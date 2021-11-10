#!/usr/bin/env bash

# For the generation of the test data https://github.com/oliver006/elasticsearch-test-data is used.

NUMBER_OF_DOCUMENTS=${1:-100000}
NUMBER_OF_INDICES=14

ELASTICSEARCH_HOST=api-int.testbed.osism.xyz
ELASTICSEARCH_PORT=9200

if [[ ! -e /usr/lib/python3/dist-packages/tornado ]]; then
    sudo apt-get install -y python3-tornado
fi

if [[ ! -e es_test_data.py ]]; then
    wget https://raw.githubusercontent.com/oliver006/elasticsearch-test-data/master/es_test_data.py
fi

for index in $(seq 1 $NUMBER_OF_INDICES); do
    python3 es_test_data.py \
      --index_name=test_data_$index \
      --es_url=http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT \
      --count=$NUMBER_OF_DOCUMENTS \
      --num_of_shards=5 \
      --num_of_replicas=1 \
      --format=name:str,age:int,last_updated:ts,message:words:50:100
done
