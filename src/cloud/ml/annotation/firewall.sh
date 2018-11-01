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

###############################################
# Open RDP ingress to allow access to Win machine on GCE
###############################################

set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

source ../../../../setenv-global.sh

# Use this to determine your current IP: https://www.whatismyip.com/
CLIENT_IP=50.205.50.2

###############################################
# Open proper ports on a firewall
###############################################
configure_firewall()
{
    echo_my "Create firewall rule to open access to Windows RDP from '$CLIENT_IP'..."
    gcloud compute --project="$PROJECT" firewall-rules create \
        remote-rdp-roman --direction=INGRESS --priority=1000 \
        --network=default --action=ALLOW --rules=tcp:3389 \
        --source-ranges=$CLIENT_IP/32 --target-tags=remote-rdp-roman
}

###############################################
# MAIN
###############################################

configure_firewall
