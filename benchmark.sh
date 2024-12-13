total_iterations=$((3 * 3 * 3 * 3 * 3))
current=0

function show_progress {
    local width=50
    local progress=$1
    local total=$2
    
    local percent=$(( (progress * 100) / total ))
    local completed=$(( (width * progress) / total ))
    
    local bar=""
    for ((i=0; i<completed; i++)); do bar+="#"; done
    for ((i=completed; i<width; i++)); do bar+="-"; done
    
    printf "\rProgress: [%s] %d%%" "$bar" "$percent"
    
    if [ $progress -eq $total ]; then
        echo
    fi
}

for alpha_ent in 0.20 0.30 0.40
do

    for k in 400 500 600
    do
        echo "preprocessing: alpha_ent $alpha_ent, k $k"

        # preprocessing (stage 2) 
        mkdir -p datasets/preprocessed-2/deezer
        docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/deezer/prepro.txt --prepro_le_file datasets/preprocessed-1/deezer/prepro_le.txt --vocab_file datasets/preprocessed-1/deezer/vocab.txt --vocab_le_file datasets/preprocessed-1/deezer/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/deezer --alpha_ent $alpha_ent --k $k > /dev/null 2>&1

        docker compose exec main python3 ./ptm/data_preprocessing/main_enrich_corpus_using_entities.py --prepro_file datasets/preprocessed-1/itunes/prepro.txt --prepro_le_file datasets/preprocessed-1/itunes/prepro_le.txt --vocab_file datasets/preprocessed-1/itunes/vocab.txt --vocab_le_file datasets/preprocessed-1/itunes/vocab_le.txt --embeddings_file_path weights/enwiki_20180420_300d.pkl --path_to_save_results datasets/preprocessed-2/itunes --alpha_ent $alpha_ent --k $k /dev/null 2>&1

        for n_topics in 40 50 60
        do

            for n_neighbours in 400 500 600
            do

                for alpha_word in 0.3 0.4 0.5
                do

                    ((current++))
                    show_progress $current $total_iterations

                    echo "alpha_ent $alpha_ent k $k n_topics $n_topics n_neighbours $n_neighbours alpha_word $alpha_word"

                    # neice model
                    docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/deezer/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/deezer --mask_entities_file datasets/preprocessed-2/deezer/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/deezer/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED /dev/null 2>&1

                    docker compose exec main python3 ./ptm/neice_model/main.py --corpus datasets/preprocessed-2/itunes/prepro_enrich_entities_th0.30_k500.txt --embeddings weights/enwiki_20180420_300d.pkl --output_dir datasets/neice/itunes --mask_entities_file datasets/preprocessed-2/itunes/mask_enrich_entities_th0.30_k500.npz --vocab datasets/preprocessed-2/itunes/new_vocab_th0.30_k500.txt --n_topics $n_topics --n_neighbours $n_neighbours --alpha_word $alpha_word --NED /dev/null 2>&1

                    # evaluation
                    docker compose exec main chmod +x ./ptm/evaluation/evaluate-topics.sh
                    T=5
                    result_deezer=$(docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/deezer/top_words.txt $T datasets/evaluation/wikipedia_bd)
                    result_itunes=$(docker compose exec main ./ptm/evaluation/evaluate-topics.sh datasets/neice/itunes/top_words.txt $T datasets/evaluation/wikipedia_bd)

                    # append csv
                    echo "$alpha_ent,$k,$n_topics,$n_neighbours,$alpha_word,$result_deezer,$result_itunes" >> ./data/results.csv
                done
            done
        done
    done
done
