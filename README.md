this is a fork of https://github.com/deezer/podcast-topic-modeling/ @ commit 6a7865f7aad0db287a8e4d43d140d42b3a94537a

# usage

```bash
#
# download data
#

# deezer
mkdir -p datasets
curl -L -o datasets/deezer.tsv https://zenodo.org/records/5834061/files/deezer_podcast_dataset.tsv?download=1 && md5sum datasets/deezer.tsv | grep d161ba83e0dfc9efb73f993a6c387dff

# itunes
mkdir -p datasets
curl -o datasets/itunes.csv https://raw.githubusercontent.com/odenizgiz/Podcasts-Data/master/df_popular_podcasts.csv
docker compose exec main python3.8 -c "import pandas as pd; pd.read_csv('datasets/itunes.csv').to_csv('datasets/itunes.tsv', sep='\t', index=False)"
rm datasets/itunes.csv

#
# entity linking
#

# download weights
mkdir -p weights
mkdir -p ./weights/tmp
for FILE in "generic" "ed-wiki-2019" "wiki_2019"
do
    wget -P ./weights/tmp "http://gem.cs.ru.nl/${FILE}.tar.gz"
    tar xvzf "./weights/tmp/${FILE}.tar.gz" -C ./data
done
rm -rf ./weights/tmp
du -sh ./weights # 62 GB

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

# download weights
mkdir -p weights
wget http://wikipedia2vec.s3.amazonaws.com/models/en/2018-04-20/enwiki_20180420_300d.pkl.bz2 -P ./weights
bzip2 -d ./weights/enwiki_20180420_300d.pkl.bz2

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
# - n_topics: number of topics to extract.
# - n_neighbours: maximum number of neighbors per cluword. (default=500)
# - alpha_word: minimum cosine similarity score between single words to be considered neighbors in a cluword. (default=0.4)
# - alpha_nmf: alpha parameter of NMF. (default=0.1)
# - l1_ratio_nmf: l1_ratio parameter of NMF. (default=0.5)
# - $NEI: independent named entity promoting strategy (default=True)
# - $NED: NE promoting strategy that gives maximum weight to singles words that are similar to NEs. (default=True)
# - NEI_alpha: independent named entity promoting parameter. (default=1.3)





```

<!--
https://github.com/deezer/podcast-topic-modeling

https://github.com/chrisizeh/podcast-topic-modeling/commit/e5f4b9787445893a5ff6ff6c929e400c081406f5#diff-0eec27339904f82c8a31e71daa26bc3a2f9dbdbaa4df9d438fc1f2c7e6d03eeaR1

https://github.com/chrisizeh/podcast-topic-modeling/commits/main/
-->




# patched

- new dockerfile with dependency dump for reproducibility
- added seeds to every file (random, numpy, torch, os) for reproducibility
- changed `df.append(d, ignore_index=True)` to `pd.concat([df, pd.DataFrame([d])], ignore_index=True)` in `main_prepro.py` since the former is deprecated and disabled
- fixed `data_preprocessing/utils.py`: path was relative to the script (not the working directory) and used linux path separators
- fixed `data_preprocessing/utils.py`: replaced `get_feature_names` with `get_feature_names_out` to resolve `AttributeError` with `CountVectorizer`
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
