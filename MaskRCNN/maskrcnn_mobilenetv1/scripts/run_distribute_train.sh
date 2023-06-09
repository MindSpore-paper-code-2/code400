#!/bin/bash
# Copyright 2020 Huawei Technologies Co., Ltd
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

if [ $# != 2 ] && [ $# != 3 ]
then 
    echo "Usage: bash run_distribute_train.sh [RANK_TABLE_FILE] [DATA_PATH] [PRETRAINED_PATH](optional)"
    exit 1
fi

get_real_path(){
    if [ "${1:0:1}" == "/" ]; then
        echo "$1"
    else
        echo "$(realpath -m $PWD/$1)"
    fi
}
PATH1=$(get_real_path $1)
PATH2=$2
PATH3=$3

echo $PATH1
echo $PATH2

if [ $# == 3 ]
then
    echo $PATH3
fi

if [ ! -f $PATH1 ]
then 
    echo "error: RANK_TABLE_FILE=$PATH1 is not a file"
    exit 1
fi 

ulimit -u unlimited
export HCCL_CONNECT_TIMEOUT=600
export DEVICE_NUM=8
export RANK_SIZE=8
export RANK_TABLE_FILE=$PATH1

echo 3 > /proc/sys/vm/drop_caches

cpus=`cat /proc/cpuinfo| grep "processor"| wc -l`
avg=`expr $cpus \/ $RANK_SIZE`
gap=`expr $avg \- 1`

for((i=0; i<${DEVICE_NUM}; i++))
do
    start=`expr $i \* $avg`
    end=`expr $start \+ $gap`
    cmdopt=$start"-"$end

    export DEVICE_ID=$i
    export RANK_ID=$i
    rm -rf ./train_parallel$i
    mkdir ./train_parallel$i
    cp ../*.py ./train_parallel$i
    cp ../*.yaml ./train_parallel$i
    cp *.sh ./train_parallel$i
    cp -r ../src ./train_parallel$i
    cd ./train_parallel$i || exit
    echo "start training for rank $RANK_ID, device $DEVICE_ID"
    env > env.log
    if [ $# == 3 ]
    then
        taskset -c $cmdopt python train.py --coco_root=$PATH2 --do_train=True  --device_id=$i \
        --rank_id=$i --run_distribute=True --device_num=$DEVICE_NUM --pre_trained=$PATH3 &> log.txt &
    fi

    if [ $# == 2 ]
    then
        taskset -c $cmdopt python train.py --coco_root=$PATH2 --do_train=True  --device_id=$i \
        --rank_id=$i --run_distribute=True --device_num=$DEVICE_NUM &> log.txt &
    fi

    cd ..
done
