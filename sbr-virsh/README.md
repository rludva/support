# sbr-virsh

## Prerequisites
Before using these scripts, ensure your host machine meets the following requirements:

- **OS:** Linux with `libvirt` installed and running..
- **ISO:** RHEL 10 ISO image must be present in the following path: `/var/lib/libvirt/images/iso/`
- **Permissions:** Root or sudo privileges are required to run `virsh` commands and modify network configurations.


## Directory Structure & Scripts
- `./bin/00-create-br0-network.sh` - Configures the network interface and defines the `br0-network` for direct external access.
- `./bin/01-generate-ks.sh` - Generates a host-specific Anaconda Kickstart file (`anaconda-ks.cfg`).
- `./bin/deploy.sh` - Provisions and installs the VM using `virt-install`.
- `./bin/remove.sh` - Safely destroys and undefines a VM.


## Deployment Steps:

### 1. Network Configuration
Run this script once to set up the bridged network (`br0`). This allows virtual machines to be directly accessible from the external network.

```bash
sudo ./bin/00-create-br0-network.sh
```

### 2. Generate Kickstart Configuration
Create the initial configuration for a specific host or use the existing one in the `hosts˛` folder.
Replace <hostname> with your desired VM name (e.g., ldap, tangd).

```bash
./bin/01-generate-ks.sh <hostname>
```

Note: This generates a static `anaconda-ks.cfg` which serves as the base for the installation.


### 3. Deploy the Virtual Machine
Once the Kickstart file is ready, run the deploy script to create the VM and start the installation process.

```bash
./bin/deploy.sh <hostname>
```

### 4. Remove a Virtual Machine
To delete a VM and remove its associated storage volumes:
```bash
./bin/remove.sh <hostname>
```