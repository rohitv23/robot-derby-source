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

set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

source ./setenv.sh
export TF_HTTP_PORT=8081

###############################################
# Main
###############################################
if [ -f "$SERVICE_ACCOUNT_SECRET" ]; then
  echo_my "Activating service account..."
  gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_SECRET
fi

rm nohup.out | true

open_http_firewall_port $TF_HTTP_PORT

set_python_path

echo "Start Tensorboard..."
nohup tensorboard --logdir=${GCS_ML_BUCKET} --port=$TF_HTTP_PORT &

echo "This script will not work on C9 VM. It needs to run on GCE or other VM. If running on GCE VM - please make sure the port above is open"

sleep 2

tail -f nohup.out
