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
wget --no-check-certificate https://hobbitdata.informatik.uni-leipzig.de/homes/mroeder/palmetto/palmetto-0.1.0-jar-with-dependencies.jar

# evaluation
mkdir -p datasets/evaluation
wget --no-check-certificate https://hobbitdata.informatik.uni-leipzig.de/homes/mroeder/palmetto/Wikipedia_bd.zip -P datasets/evaluation
unzip datasets/evaluation/Wikipedia_bd.zip -d datasets/evaluation
rm -rf datasets/evaluation/Wikipedia_bd.zip

#
# entity linking
#

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

# variables:
# - T: cut-off value for score: 10 (in the paper)

# deezer
docker compose exec main chmod +x ./ptm/evaluation/evaluate-topics.sh
docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/deezer/top_words.txt 10 datasets/evaluation/wikipedia_bd

# itunes
docker compose exec main chmod +x ./ptm/evaluation/evaluate-topics.sh
docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/deezer/top_words.txt 10 datasets/evaluation/wikipedia_bd
