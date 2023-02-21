# Download the Artifacts Playbook
* This playbook is downloading all aretfacts that are important for installation of OpenShift Container Platform.
* The artefacts as RHCOS images are moved to the current directory from which the ansible-playbook is executed, so before running this playbook process the `cd` command to change the current directory to one from where you want the files be accessed. 
* The OpenShift CLI tool `oc` and `openshift-install` is move to `/usr/local/sbin` and also to the current directory.
