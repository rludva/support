# sbr-virsh

- This folder contains an example virtual machine hosts like ldap and tangd  which are created and installed via `libvirt` and `./bin/deploy.sh`.
- To process it, you need to have `libvirt` installed on your system.
- The initial anaconda-ks.cfg file is generated via `./bin/01-generate-ks.sh <hostname>`.
- When Anaconda Kickstart file is generated and anaconda-ks.cfg file is created use `./bin/deploy.sh <hostname>` to create and install the VM.
- To remove the VM use `./bin/remove.sh <hostname>`.
