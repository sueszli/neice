current=0

for alpha_ent in 0.30 0.40 # from paper
do

    for k in 20 50 100 200 # from paper (default=500, not used in paper)
    do
        start_time=$(date +%s)

        # preprocessing stage 2
        mkdir -p datasets/preprocessed-2/deezer
        docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/deezer/prepro.txt --prepro_le_file datasets/preprocessed-1/deezer/prepro_le.txt --vocab_file datasets/preprocessed-1/deezer/vocab.txt --vocab_le_file datasets/preprocessed-1/deezer/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/deezer --alpha_ent $alpha_ent --k $k > /dev/null 2>&1

        docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/itunes/prepro.txt --prepro_le_file datasets/preprocessed-1/itunes/prepro_le.txt --vocab_file datasets/preprocessed-1/itunes/vocab.txt --vocab_le_file datasets/preprocessed-1/itunes/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/itunes --alpha_ent $alpha_ent --k $k > /dev/null 2>&1

        # log
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "preprocessing (executed in $elapsed_time s) - alpha_ent $alpha_ent, k $k"

        for n_topics in 10 20 50 100 # common values (default=50)
        do

            for n_neighbours in 5 10 20 500 # common values (default=500, but very uncommon)
            do

                for alpha_word in 0.2 0.3 0.4 0.5 # from paper
                do
                    start_time=$(date +%s)

                    # neice model
                    docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/deezer/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/deezer --mask_entities_file datasets/preprocessed-2/deezer/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/deezer/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED > /dev/null 2>&1

                    docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/itunes/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/itunes --mask_entities_file datasets/preprocessed-2/itunes/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/itunes/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED > /dev/null 2>&1

                    # evaluation
                    docker compose exec main chmod +x ./ptm/evaluation/evaluate-topics.sh
                    result_deezer=$(docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/deezer/top_words.txt 10 datasets/evaluation/wikipedia_bd)
                    result_itunes=$(docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/itunes/top_words.txt 10 datasets/evaluation/wikipedia_bd)

                    # append csv
                    echo "$alpha_ent,$k,$n_topics,$n_neighbours,$alpha_word,$result_deezer,$result_itunes" >> ./data/results.csv

                    # log
                    end_time=$(date +%s)
                    elapsed_time=$((end_time - start_time))
                    total_iterations=$((2 * 4 * 4 * 4 * 4))
                    current=$((current+1))
                    echo "iteration $current/$total_iterations (executed in $elapsed_time s) - alpha_ent $alpha_ent, k $k, n_topics $n_topics, n_neighbours $n_neighbours, alpha_word $alpha_word"
                done
            done
        done
    done
done
