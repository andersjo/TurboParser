make
make install
GLOG_logtostderr=1 ./TurboParser --model_type=basic --prune_basic=0 --train --file_train=data/sample/sample_train.conll --file_model=models/sample_parser.model
GLOG_logtostderr=1 ./TurboParser --model_type=basic --test --evaluate --file_test=data/sample/sample_test.conll --file_model=models/sample_parser.model --file_prediction=data/sample/sample_test.conll.predicted
