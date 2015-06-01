make
make install
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:`pwd;`/deps/local/lib:"
mkdir -p models
GLOG_logtostderr=1 ./TurboParser --model_type=basic \
	--prune_basic=1 --prune_labels=1 --prune_distances=1 \
	--train \
	--file_train=data/sample/sample_train.conll \
	--file_model=models/sample_parser.model
GLOG_logtostderr=1 ./TurboParser \
	--model_type=basic \
	--test --evaluate \
	--file_test=data/sample/sample_test.conll \
	--file_model=models/sample_parser.model \
	--file_prediction=data/sample/sample_test.conll.predicted \
	--output_scores
