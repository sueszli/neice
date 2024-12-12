this is a patch of
fork https://github.com/deezer/podcast-topic-modeling/
at commit 6a7865f7aad0db287a8e4d43d140d42b3a94537a

# usage

```bash
# 
# download data
# 

mkdir -p datasets

# deezer
curl -L -o datasets/deezer.tsv https://zenodo.org/records/5834061/files/deezer_podcast_dataset.tsv?download=1 && md5sum datasets/deezer.tsv | grep d161ba83e0dfc9efb73f993a6c387dff

# itunes
curl -o datasets/itunes.csv https://raw.githubusercontent.com/odenizgiz/Podcasts-Data/master/df_popular_podcasts.csv
docker compose exec main python3.8 -c "import pandas as pd; pd.read_csv('datasets/itunes.csv').to_csv('datasets/itunes.tsv', sep='\t', index=False)"
rm datasets/itunes.csv

# 
# download named entity recognition weights
# 

mkdir -p weights
mkdir -p ./weights/tmp
for FILE in "generic" "ed-wiki-2019" "wiki_2019"
do
    wget -P ./weights/tmp "http://gem.cs.ru.nl/${FILE}.tar.gz"
    tar xvzf "./weights/tmp/${FILE}.tar.gz" -C ./data
done
rm -rf ./weights/tmp
du -sh ./weights # 62 GB

# 
# preprocessing: extract all named entities into a json
# 

docker compose exec main echo 'done'

./.venv/bin/python3 ./ptm/entity_linking/radboud_entity_linker_batch.py datasets/deezer.tsv datasets/named_entities weights --batch_size 128 --wiki_version wiki_2019



```

# patches



# unable to patch

- note by authors: updated dependencies (REL, flairNLP) means different word vocabulary, which means different topic coherence scores than the original paper → results changed but should have the same distribution

- spotify dataset not available since dec 2023 (https://podcastsdataset.byspotify.com/)

- container:

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
