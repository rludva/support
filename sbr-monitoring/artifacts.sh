#!/bin/bash

# This script is used to start download of artifactories from the artifactory server
ansible-playbook ./playbooks/artifacts.yaml -e "application=prometheus"
ansible-playbook ./playbooks/artifacts.yaml -e "application=alertmanager"
ansible-playbook ./playbooks/artifacts.yaml -e "application=node_exporter"