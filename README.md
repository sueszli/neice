this is a patch of
fork https://github.com/deezer/podcast-topic-modeling/
at commit 6a7865f7aad0db287a8e4d43d140d42b3a94537a

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
docker compose exec main python3 ./ptm/entity_linking/radboud_entity_linker_batch.py datasets/deezer.tsv datasets/named_entities/deezer weights --batch_size 128 --wiki_version wiki_2019 # takes 3h
docker compose exec main python3 ./ptm/entity_linking/join_predictions.py datasets/named_entities/deezer datasets/deezer.tsv --batch_size 128

# itunes
mkdir -p datasets/named_entities/itunes
docker compose exec main python3 ./ptm/entity_linking/radboud_entity_linker_batch.py datasets/itunes.tsv datasets/named_entities/itunes weights --batch_size 128 --wiki_version wiki_2019 --col_title 'Name' --col_description 'Description' # takes 3h
docker compose exec main python3 ./ptm/join_predictions.py datasets/named_entities/itunes datasets/itunes.tsv --batch_size 128 --col_title 'Name' --col_description 'Description'

# 
# data preprocessing
# 
```

<!--
https://github.com/deezer/podcast-topic-modeling

https://github.com/chrisizeh/podcast-topic-modeling/commits/main/

https://github.com/chrisizeh/podcast-topic-modeling/commit/e5f4b9787445893a5ff6ff6c929e400c081406f5#diff-0eec27339904f82c8a31e71daa26bc3a2f9dbdbaa4df9d438fc1f2c7e6d03eeaR1
-->

# patches

- new dockerfile with dependency dump for reproducibility

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

    - almost worked, but `gcld3` doesn't build on arm64, even if you install the protobuf dependency → stopped using virtualenv
