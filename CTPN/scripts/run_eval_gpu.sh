#!/bin/bash
# Copyright 2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

if [ $# != 3 ] && [ $# != 4 ]
then
    echo "Usage: bash scripts/run_eval_gpu.sh [IMAGE_PATH] [DATASET_PATH] [CHECKPOINT_PATH] [CONFIG_PATH](optional)"
exit 1
fi

get_real_path(){
  if [ "${1:0:1}" == "/" ]; then
    echo "$1"
  else
    echo "$(realpath -m $PWD/$1)"
  fi
}
IMAGE_PATH=$(get_real_path $1)
DATASET_PATH=$(get_real_path $2)
CHECKPOINT_PATH=$(get_real_path $3)
echo $IMAGE_PATH
echo $DATASET_PATH
echo $CHECKPOINT_PATH

if [ ! -d $IMAGE_PATH ]
then 
    echo "error: IMAGE_PATH=$PATH1 is not a path"
exit 1
fi

if [ ! -f $DATASET_PATH ]
then 
    echo "error: CHECKPOINT_PATH=$DATASET_PATH is not a path"
exit 1
fi

if [ ! -d $CHECKPOINT_PATH ]
then 
    echo "error: CHECKPOINT_PATH=$CHECKPOINT_PATH is not a directory"
exit 1
fi
BASE_PATH=$(cd ./"`dirname $0`" || exit; pwd)
CONFIG_PATH=$BASE_PATH/../default_config.yaml
if [ $# == 4 ]
then
    CONFIG_PATH=$(get_real_path $4)
    echo $CONFIG_PATH
fi
export DEVICE_NUM=1
export RANK_SIZE=$DEVICE_NUM
export RANK_ID=0
for file in "${CHECKPOINT_PATH}"/*.ckpt
do
    if [ -d "eval" ];
    then
        rm -rf ./eval
    fi
    mkdir ./eval
    cp ./*.py ./eval
    cp -r ./scripts ./eval
    cp -r ./src ./eval
    cp ./*yaml ./eval
    cd ./eval || exit
    env > env.log
    CHECKPOINT_FILE_PATH=$file
    echo "start eval for checkpoint file: ${CHECKPOINT_FILE_PATH}"
    python eval.py --image_path=$IMAGE_PATH --dataset_path=$DATASET_PATH --checkpoint_path=$CHECKPOINT_FILE_PATH \
        --device_target="GPU" --config_path=$CONFIG_PATH &> log
    echo "end eval for checkpoint file: ${CHECKPOINT_FILE_PATH}"
    cd ./submit || exit
    file_base_name=$(basename $file)
    zip -r ../../submit_${file_base_name%.*}.zip *.txt
    cd ../../
done

