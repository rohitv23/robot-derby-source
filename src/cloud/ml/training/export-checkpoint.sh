#!/bin/bash

#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#####################################################################################
# If your model failed for any reason or it is still training and has not reached the 
# final number of training steps, you can still export the checkpoint to experiment with it. 
# If the model is still training, you will need to create a separate VM to do the export 
# (same steps as you used to create this VM). In order to do the export, edit the script 
# export-checkpoint.sh and update the variable to the checkpoint number found in the GCS 
# bucket as shown above (the actual number will be different for your bucket): 
# export CHECKPOINT_NUMBER=1735
#####################################################################################

set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

source ./setenv.sh

CWD=`pwd`
TMP=$CWD/tmp

##################################################
# Export the checkpoint
##################################################
export_tf_checkpoint() {
    echo_my "export_tf_checkpoint(): Export started..."
    export CHECKPOINT_NUMBER=$TRAINING_STEPS
    export EXPORT_PATH=$TMP/export
    rm -rf ${EXPORT_PATH} | true # inore if this does not exist yet
    mkdir -p ${EXPORT_PATH}
    cd $EXPORT_PATH

    gsutil cp ${GCS_ML_BUCKET}/train/model.ckpt-${CHECKPOINT_NUMBER}.* .
    
    echo_my "Processing checkpoint data..."
    # This command below does not seem to be necessary on Deep Learning VM
    # activate
    python $TF_MODEL_DIR/models/research/object_detection/export_inference_graph.py \
        --input_type image_tensor \
        --pipeline_config_path $MODEL_CONFIG_PATH/${MODEL_CONFIG} \
        --trained_checkpoint_prefix model.ckpt-${CHECKPOINT_NUMBER} \
        --output_directory ./
        
    echo_my "Prepare GCS bucket..."
    gsutil mb -l $REGION -c regional ${ML_EXPORT_BUCKET} | true # ignore if it is already there

    echo_my "Copy frozen inference graph to GCS '$FROZEN_INFERENCE_GRAPH_GCS' for reuse in Obj Detection API..."
    gsutil cp frozen_inference_graph.pb $FROZEN_INFERENCE_GRAPH_GCS
    
    echo_my "Copy label map to GCS '$LABEL_MAP_GCS' for reuse in Obj Detection API..."
    cd $TMP
    gsutil cp object_detection/annotations/$LABEL_MAP $LABEL_MAP_GCS
}

#############################################
# MAIN
#############################################
print_header "Exporting Frozen Inference Graph"

cd $TF_MODEL_DIR/models/research
export PYTHONPATH=`pwd`:`pwd`/slim:`pwd`/object_detection
echo_my "PYTHONPATH=$PYTHONPATH"

export_tf_checkpoint

print_footer "Inference Graph export has completed"
