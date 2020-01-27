#!/bin/bash

# Note: VM custom scripts run as root and this is required to install the vsts-agant as root
export AGENT_ALLOW_RUNASROOT=TRUE
cd /home/${username}

curl https://vstsagentpackage.azureedge.net/agent/2.164.6/vsts-agent-linux-x64-2.164.6.tar.gz -o vsts-agent.tar.gz
mkdir vsts-agent
tar -xvf vsts-agent.tar.gz --directory vsts-agent

cd vsts-agent
./config.sh --unattended --url ${devOpsUrl} --auth pat --token ${pat} --pool ${pool} --agent $HOSTNAME --replace  --acceptTeeEula

sudo ./svc.sh install
sudo ./svc.sh start