#!/bin/bash

# Root folder where TurboParser is installed.
root_folder="`cd $(dirname $0);cd ../..;pwd`"
task_folder="`cd $(dirname $0);cd ..;pwd`"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${root_folder}/deps/local/lib"

# Set options.
language=$1 # Example: "slovene" or "english_proj".
train_algorithm=svm_mira # Training algorithm.
num_epochs=$3 #10 # Number of training epochs.
regularization_parameter=$4 #0.001 # The C parameter in MIRA.
train_cost_false_positives=$5
train_cost_false_negatives=$6
ignore_null_labels=$7 #false #true
train=true
test=true
case_sensitive=false # Distinguish word upper/lower case.
form_cutoff=0 # Cutoff in word occurrence.
lemma_cutoff=0 # Cutoff in lemma occurrence.

suffix_indexer=$2 #parser_pruned-true_model-full.pred.labeler.pred.conv.trees
suffix=constituency_labeler

# Set path folders.
path_bin=${root_folder} # Folder containing the binary.
path_scripts=${task_folder}/scripts # Folder containing scripts.
path_data=${task_folder}/data/${language} # Folder with the data.
path_models=${task_folder}/models/${language} # Folder where models are stored.
path_results=${task_folder}/results/${language} # Folder for the results.

# Create folders if they don't exist.
mkdir -p ${path_data}
mkdir -p ${path_models}
mkdir -p ${path_results}

# Set file paths. Allow multiple test files.
file_model=${path_models}/${language}_${suffix}.model
file_results=${path_results}/${language}_${suffix}.txt

if [ "$language" == "english_ptb" ]
then
    discontinuous=false
    evalb_bin=${path_scripts}/EVALB/evalb
    evalb_parameter_file=${path_scripts}/EVALB/COLLINS_new.prm

    file_train=${path_data}/${language}_train.trees.predpos
    #file_train=${path_data}/${language}_train.trees.predpos
    files_test[0]=${path_data}/${language}_test.trees
    files_test[1]=${path_data}/${language}_dev.trees
    files_test_indexed[0]=${path_data}/${language}_ftags_test.conll.predpos.${suffix_indexer}
    files_test_indexed[1]=${path_data}/${language}_ftags_dev.conll.predpos.${suffix_indexer}
else
    if [ "$language" == "tgpred" ]
    then
	discontinuous=true
	discontinuous_kind=TIGER
	evalb_bin=${path_scripts}/disco-dop/discodop/eval.py
	evalb_parameter_file=${path_scripts}/evalb_spmrl2013/spmrl.prm
	use_dev=true
    elif [ "$language" == "hnpred" ]
    then
	discontinuous=true
	discontinuous_kind=TIGER
	evalb_bin=${path_scripts}/disco-dop/discodop/eval.py
	evalb_parameter_file=${path_scripts}/disco-dop/discodop/proper.prm	
	use_dev=false
    elif [ "$language" == "ngpred" ]
    then
	discontinuous=true
	discontinuous_kind=NEGRA
	evalb_bin=${path_scripts}/disco-dop/discodop/eval.py
	evalb_parameter_file=${path_scripts}/disco-dop/discodop/proper.prm	
	use_dev=false
    else
	discontinuous=false
	evalb_bin=${path_scripts}/evalb_spmrl2013/evalb_spmrl
	evalb_parameter_file=${path_scripts}/evalb_spmrl2013/spmrl.prm
	use_dev=true
    fi

    file_train=${path_data}/${language}_train.trees
    if ${use_dev}
    then
	files_test[0]=${path_data}/${language}_test.trees
	files_test[1]=${path_data}/${language}_dev.trees
	files_test_indexed[0]=${path_data}/${language}_ftags_test.conll.${suffix_indexer}
	files_test_indexed[1]=${path_data}/${language}_ftags_dev.conll.${suffix_indexer}
    else
	files_test[0]=${path_data}/${language}_test.trees
	files_test_indexed[0]=${path_data}/${language}_ftags_test.conll.${suffix_indexer}
    fi
fi

# Obtain a prediction file path for each test file.
for (( i=0; i<${#files_test[*]}; i++ ))
do
    file_test=${files_test[$i]}
    file_test_indexed=${files_test_indexed[$i]}
    file_prediction=${file_test}.${suffix}.pred
    file_prediction_indexed=${file_test_indexed}.${suffix}.pred
    files_prediction[$i]=${file_prediction}
    files_prediction_indexed[$i]=${file_prediction_indexed}
done


# Evaluate what happens when we don't add unaries at all (useful in TIGER and NEGRA).
for (( i=0; i<${#files_test[*]}; i++ ))
do
    echo "Evaluating (skipping unary predictor)..."
    touch ${file_results}
    if ${discontinuous}
    then
	java -jar -Dfile.encoding=utf-8 trees2export.jar ${files_test[$i]} ${discontinuous_kind}
	java -jar -Dfile.encoding=utf-8 trees2export.jar ${files_test_indexed[$i]} ${discontinuous_kind}
	${evalb_bin} ${files_test[$i]}.export ${files_test_indexed[$i]}.export ${evalb_parameter_file} | grep '^labeled' | head -3 \
            >> ${file_results}
    else
        ${evalb_bin} -p ${evalb_parameter_file} ${files_test[$i]} ${file_prediction} | grep Bracketing | head -3 \
	    >> ${file_results}
    fi
    cat ${file_results}

    echo "FINAL SCORE NO UNARIES: `tail -1 ${file_results}`"
done


################################################
# Train the parser.
################################################

if $train
then
    ${path_bin}/TurboConstituencyLabeler \
        --train \
        --train_epochs=${num_epochs} \
        --file_model=${file_model} \
        --file_train=${file_train} \
        --form_case_sensitive=${case_sensitive} \
        --form_cutoff=${form_cutoff} \
        --lemma_cutoff=${lemma_cutoff} \
        --train_algorithm=${train_algorithm} \
        --train_regularization_constant=${regularization_parameter} \
        --constituency_labeler_train_cost_false_positives=${train_cost_false_positives} \
        --constituency_labeler_train_cost_false_negatives=${train_cost_false_negatives} \
        --ignore_null_labels=${ignore_null_labels} \
        --logtostderr
fi


################################################
# Test the parser.
################################################

if $test
then

    rm -f ${file_results}

    # Test first with gold trees with unaries stripped.
    for (( i=0; i<${#files_test[*]}; i++ ))
    do
        file_test=${files_test[$i]}
        file_prediction=${files_prediction[$i]}

        echo ""
        echo "Testing on ${file_test}..."
        ${path_bin}/TurboConstituencyLabeler \
            --test \
            --evaluate \
            --file_model=${file_model} \
            --file_test=${file_test} \
            --file_prediction=${file_prediction} \
            --logtostderr

        echo ""
        echo "Evaluating..."
        touch ${file_results}
	if ${discontinuous}
	then
	    java -jar -Dfile.encoding=utf-8 trees2export.jar ${files_test[$i]} ${discontinuous_kind}
	    java -jar -Dfile.encoding=utf-8 trees2export.jar ${files_prediction[$i]} ${discontinuous_kind}
	    ${evalb_bin} ${files_test[$i]}.export ${files_prediction[$i]}.export ${evalb_parameter_file} | grep '^labeled' | head -3 \
                >> ${file_results}
	else
            ${evalb_bin} -p ${evalb_parameter_file} ${files_test[$i]} ${files_prediction[$i]} | grep Bracketing | head -3 \
		>> ${file_results}
	fi
        cat ${file_results}
    done

    # Now test on predicted trees with unaries, coming from the pipeline.
    for (( i=0; i<${#files_test[*]}; i++ ))
    do
        file_test=${files_test_indexed[$i]}
        file_prediction=${files_prediction_indexed[$i]}

        echo ""
        echo "Testing on ${file_test}..."
        ${path_bin}/TurboConstituencyLabeler \
            --test \
            --evaluate \
            --file_model=${file_model} \
            --file_test=${file_test} \
            --file_prediction=${file_prediction} \
            --logtostderr

        echo ""
        echo "Evaluating..."
        touch ${file_results}
	if ${discontinuous}
	then
	    java -jar -Dfile.encoding=utf-8 trees2export.jar ${files_test[$i]} ${discontinuous_kind}
	    java -jar -Dfile.encoding=utf-8 trees2export.jar ${file_prediction} ${discontinuous_kind}

	    ${evalb_bin} ${files_test[$i]}.export ${file_prediction}.export ${evalb_parameter_file} | grep '^labeled' | head -3 \
                >> ${file_results}
	else
            ${evalb_bin} -p ${evalb_parameter_file} ${files_test[$i]} ${file_prediction} | grep Bracketing | head -3 \
		>> ${file_results}
	fi
        cat ${file_results}

        echo "FINAL SCORE: `tail -1 ${file_results}`"
    done
fi
