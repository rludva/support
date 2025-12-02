# sbr-virsh

- This folder contains an example virtual machine host `ldap.example.com` which is created and installed via `libvirt` and `virt-install` using `virsh` commands.
- To process it, you need to have `libvirt` and `virt-install` installed on your system.
- The VM is configured via a ./ldap.example.com/bin/01-generate-ks.sh which generates a kickstart file for automated installation.
- Then execute the ./ldap.example.com/bin/virsh-install.sh to create and install the VM.
