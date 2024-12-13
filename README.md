# neice: named entity informed corpus embedding

reproducing: https://arxiv.org/pdf/2201.04419

this repository is a fork of https://github.com/deezer/podcast-topic-modeling/ @ commit 6a7865f7aad0db287a8e4d43d140d42b3a94537a

# usage

```bash
#
# download data and weights
#

# deezer
mkdir -p datasets
curl -L -o datasets/deezer.tsv https://zenodo.org/records/5834061/files/deezer_podcast_dataset.tsv?download=1 && md5sum datasets/deezer.tsv | grep d161ba83e0dfc9efb73f993a6c387dff

# itunes
mkdir -p datasets
curl -o datasets/itunes.csv https://raw.githubusercontent.com/odenizgiz/Podcasts-Data/master/df_popular_podcasts.csv
docker compose exec main python3.8 -c "import pandas as pd; pd.read_csv('datasets/itunes.csv').to_csv('datasets/itunes.tsv', sep='\t', index=False)"
rm datasets/itunes.csv

# entity linking
mkdir -p weights
mkdir -p ./weights/tmp
for FILE in "generic" "ed-wiki-2019" "wiki_2019"
do
    wget -P ./weights/tmp "http://gem.cs.ru.nl/${FILE}.tar.gz"
    tar xvzf "./weights/tmp/${FILE}.tar.gz" -C ./data
done
rm -rf ./weights/tmp
du -sh ./weights

# preprocessing
mkdir -p weights
wget http://wikipedia2vec.s3.amazonaws.com/models/en/2018-04-20/enwiki_20180420_300d.pkl.bz2 -P ./weights
bzip2 -d ./weights/enwiki_20180420_300d.pkl.bz2

# evaluation
mkdir -p libs
wget --no-check-certificate https://hobbitdata.informatik.uni-leipzig.de/homes/mroeder/palmetto/palmetto-0.1.0-jar-with-dependencies.jar
mv palmetto-0.1.0-jar-with-dependencies.jar libs

# evaluation
mkdir -p datasets/evaluation
wget --no-check-certificate https://hobbitdata.informatik.uni-leipzig.de/homes/mroeder/palmetto/Wikipedia_bd.zip -P datasets/evaluation
unzip datasets/evaluation/Wikipedia_bd.zip
rm -rf datasets/evaluation/Wikipedia_bd.zip

#
# entity linking
#

# fix numpy dtype error
docker compose exec main pip install numpy==1.26.4

# deezer
mkdir -p datasets/named_entities/deezer
docker compose exec main python3 ./ptm/entity_linking/radboud_entity_linker_batch.py datasets/deezer.tsv datasets/named_entities/deezer weights --batch_size 128 --wiki_version wiki_2019
docker compose exec main python3 ./ptm/entity_linking/join_predictions.py datasets/named_entities/deezer datasets/deezer.tsv --batch_size 128

# itunes
mkdir -p datasets/named_entities/itunes
docker compose exec main python3 ./ptm/entity_linking/radboud_entity_linker_batch.py datasets/itunes.tsv datasets/named_entities/itunes weights --batch_size 128 --wiki_version wiki_2019 --col_title 'Name' --col_description 'Description'
docker compose exec main python3 ./ptm/entity_linking/join_predictions.py datasets/named_entities/itunes datasets/itunes.tsv --batch_size 128 --col_title 'Name' --col_description 'Description'

#
# preprocessing (stage 1)
#

# variables:
# - threshold: minimum score value to keep the linked entity. (default=0.9) -> keep as is
# - vocab_size: vocab size. (default=None) -> keep as is
# - min_df: keep those words in the vocabulary whose frequency will be greater than min_df. (default=5) -> keep as is
# - min_words: minimum number of words per preprocessed document. (default=2) -> keep as is

# deezer
mkdir -p datasets/preprocessed-1/deezer
docker compose exec main python3 ./ptm/data_preprocessing/main_prepro.py --examples_file datasets/deezer.tsv --annotated_file datasets/named_entities/deezer/linked_entities.json --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-1/deezer

# itunes
mkdir -p datasets/preprocessed-1/itunes
docker compose exec main python3 ./ptm/data_preprocessing/main_prepro.py --examples_file datasets/itunes.tsv --annotated_file datasets/named_entities/itunes/linked_entities.json --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-1/itunes --col_title 'Name' --col_description 'Description'

#
# preprocessing (stage 2)
#

# variables:
# - alpha_ent: minimum cosine similarity score between single words and entities. (default=0.3)
# - d: word embedding size. (default=300) -> keep as is
# - k: maximum number of nearest single words per entity. (default=500)

# deezer
mkdir -p datasets/preprocessed-2/deezer
alpha_ent=0.3
k=500
docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/deezer/prepro.txt --prepro_le_file datasets/preprocessed-1/deezer/prepro_le.txt --vocab_file datasets/preprocessed-1/deezer/vocab.txt --vocab_le_file datasets/preprocessed-1/deezer/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/deezer --alpha_ent $alpha_ent --k $k

# itunes
mkdir -p datasets/preprocessed-2/itunes
alpha_ent=0.3
k=500
docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/itunes/prepro.txt --prepro_le_file datasets/preprocessed-1/itunes/prepro_le.txt --vocab_file datasets/preprocessed-1/itunes/vocab.txt --vocab_le_file datasets/preprocessed-1/itunes/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/itunes --alpha_ent $alpha_ent --k $k

#
# neice model
#

# variables:
# - n_topics/n_components: number of topics to extract.
# - n_neighbours: maximum number of neighbors per cluword. (default=500)
# - alpha_word: minimum cosine similarity score between single words to be considered neighbors in a cluword. (default=0.4)
# - alpha_nmf: alpha parameter of NMF. (default=0.1) -> keep as is (too sensitive, typically set to small values like 0.00005 to avoid over-regularization)
# - l1_ratio_nmf: l1_ratio parameter of NMF. (default=0.5) -> keep as is
# - $NEI: independent named entity promoting strategy (default=True) -> keep as is
# - $NED: NE promoting strategy that gives maximum weight to singles words that are similar to NEs. (default=True) -> keep as is
# - NEI_alpha: independent named entity promoting parameter. (default=1.3) -> keep as is

# deezer
mkdir -p datasets/neice/deezer
n_topics=50
n_neighbours=500
alpha_word=0.4
docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/deezer/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/deezer --mask_entities_file datasets/preprocessed-2/deezer/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/deezer/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED

# itunes
mkdir -p datasets/neice/itunes
n_topics=50
n_neighbours=500
alpha_word=0.4
docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/itunes/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/itunes --mask_entities_file datasets/preprocessed-2/itunes/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/itunes/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED

# 
# evaluation
# 

# deezer
TOPICS_MODEL_FILE=$1
NUMBER_TOP_WORDS=$2
WIKIPEDIA_DB_PATH=$3

TMP_T_TOP_WORDS="/tmp/$2_top_words.txt"
python3 extract_t_top_words.py --input $1 --output ${TMP_T_TOP_WORDS} --T $2
TMP_CV_SCORES_RAW="/tmp/T=$2_CV_raw.txt"
java -jar palmetto-0.1.0-jar-with-dependencies.jar $3 "C_V" ${TMP_T_TOP_WORDS} > ${TMP_CV_SCORES_RAW}
TMP_CV_SCORES="/tmp/T=$2_CV.txt"
echo "CV" > ${TMP_CV_SCORES}
tail -n $2 ${TMP_CV_SCORES_RAW} | awk '{print $2}' >> ${TMP_CV_SCORES}
TMP_FILE=${TMP_CV_SCORES}
export TMP_FILE
python3 -c "import pandas as pd; import os; df = pd.read_csv(os.environ['TMP_FILE']); print(df['CV'].mean()* 100)"

# Input:

# $TOPICS_MODEL_FILE: the file which contains the top words of each topic (top_words.txt).
# $NUMBER_TOP_WORDS: the number of words considered per topic (T).
# $WIKIPEDIA_DB_PATH: the path to the Wikipedia database wikipedia_bd, previously downloaded and unzipped.

```

# evaluation loop

<!--
https://github.com/deezer/podcast-topic-modeling

https://github.com/chrisizeh/podcast-topic-modeling/commits/main/
-->

run eval loop after a single iteration as shown above was successful

```bash

# write to ./data
# analyze in docs

for K in 20 50 100 200
do

    for alpha_ent in 0.30 0.40
    do
        python3 ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file ${DIR}/prepro.txt \
            --prepro_le_file ${DIR}/prepro_le.txt \
            --vocab_file ${DIR}/vocab.txt \
            --vocab_le_file ${DIR}/vocab_le.txt \
            --embeddings_file_path ${DIR}/enwiki_20180420_300d.pkl \
            --path_to_save_results ${DIR} \
            --alpha_ent ${alpha_ent} \
            --k ${K}

        for alpha_word in 0.2 0.3 0.4 0.5
        do
            python3 ptm/neice_model/main.py \
                --corpus ${DIR}/prepro_enrich_entities_th${alpha_ent}_k${K}.txt \
                --embeddings ${DIR}/enwiki_20180420_300d.pkl \
                --output_dir ${DIR} \
                --mask_entities_file ${DIR}/mask_enrich_entities_th${alpha_ent}_k${K}.npz \
                --vocab ${DIR}/new_vocab_th${alpha_ent}_k${K}.txt \
                --n_topics ${T} \
                --n_neighbours ${K} \
                --alpha_word ${alpha_word} \
                --NED

            cd ptm/evaluation
            echo "K ${K} T ${T} alpha_word ${alpha_word} alpha_ent ${alpha_ent}: " >> ../../results_deezer_${i}.txt
            ./evaluate-topics.sh ${DIR}/top_words.txt ${T} ${DIR}/wikipedia_bd  >> ../../results_deezer_${i}.txt
            echo "\n" >> ../../results_deezer_${i}.txt
            cd ../../
        done
    done
done
```

# patched

- new dockerfile with dependency dump for reproducibility
- added seeds to every file (random, numpy, torch, os), so a single iteration is sufficient for evaluation
- changed `df.append(d, ignore_index=True)` to `pd.concat([df, pd.DataFrame([d])], ignore_index=True)` in `main_prepro.py` since the former is deprecated and disabled
- fixed `data_preprocessing/utils.py`: path was relative to the script (not the working directory) and used linux path separators
- fixed `data_preprocessing/utils.py` and `neice_model/wikipedia2vec_model.py`: replaced `get_feature_names` with `get_feature_names_out` to resolve `AttributeError` with `CountVectorizer`
- fixed `neice_model.py`: replaced sklearn `NMF` argument `alpha` with `alpha_W` to resolve non existent parameter error

# unable to patch

- note by authors: updated dependencies (REL, flairNLP) mean a different vocabulary. this makes it impossible to reproducible exact scores from original paper. however the distribution of scores should be similar.
- spotify dataset not available since dec 2023 (https://podcastsdataset.byspotify.com/)
- provided container:
    - doesn't build
        - the REL git dependency always pulls the latest commit, so it doesn't match the requirements.txt
        - i took a commit from march 2022, when this paper was submitted
    - not portable
        - set arch emulation flag so it works on arm64
    - needs gpu
        - can't use docker in google colab due to cgroup configuration bug (there is no way to resolve this)
        - chose CPU only implementation, rewrite container config
    - needs to be run interactively
        - fix with compose: `docker compose build && docker compose up -d && docker compose exec main echo 'done'`
    - breaks on: `entity_linking/radboud_entity_linker_batch.py`:
        - REL dependency missmatch: manually find and downgrade the right dependencies, freeze pip in container into `requirements.txt`
        - flair NER model needs `SequenceTagger` wrapper and weights from Feb 26, 2021 commit on huggingface:
            ```python
            from flair.models import SequenceTagger
            tagger_ner = SequenceTagger.load('flair/ner-english-fast@3d3d35790f78a00ef319939b9004209d1d05f788')
            ```
        - cryptic SQLite errors when calling `MentionDetection`, unable to patch → stopped using container provided in repository
- virtualenv:
    - almost worked, but `gcld3` doesn't build on arm64, even if you install the protobuf dependency → stopped using virtualenv, had to use docker or conda (chose docker)
- the weights in `enwiki_20180420_300d.pkl` are not byte aligned which can throw segfaults when used with some of the libraries

# kudos

thanks to `@chrisizeh` and `@DennisToma` for an alternative reproduction of the paper: https://github.com/chrisizeh/podcast-topic-modeling
