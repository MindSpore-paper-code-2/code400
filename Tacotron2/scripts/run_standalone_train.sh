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
echo "=============================================================================================================="
echo "Please run the script as: "
echo "bash run_standalone_train.sh DATASET_PATH DEVICE_ID"
echo "example: bash run_standalone_train.sh ./data/ljspeech.hdf5 0"
echo "It is better to use absolute path."
echo "Please pay attention that the dataset should corresponds to dataset_name"
echo "=============================================================================================================="
if [[ $# -lt 2 ]]; then
  echo "Usage: bash run_standalone_train.sh [DATA_PATH] [DEVICE_ID]
  DATANAME can choose from [ljspeech]"
exit 1
fi

get_real_path(){
  if [ "${1:0:1}" == "/" ]; then
    echo "$1"
  else
    echo "$(realpath -m $PWD/$1)"
  fi
}

DATASET=$(get_real_path $1)
DEVICEID=$2

config_path="./ljspeech_config.yaml"
echo "config path is : ${config_path}"

export DEVICE_NUM=1
export DEVICE_ID=$DEVICEID
export RANK_ID=0
export RANK_SIZE=1


if [ -d "train" ];
then
    rm -rf ./train
fi
mkdir ./train
cp ../*.py ./train
cp ../*.yaml ./train
cp -r ../src ./train
cp -r ../model_utils ./train
cp -r ../scripts/*.sh ./train
cd ./train || exit
echo "start training for device $DEVICE_ID"
env > env.log
python train.py --config_path $config_path --dataset_path $DATASET > standalone_tacotron2.log 2>&1 &
cd ..
