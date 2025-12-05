#!/bin/bash

# 1. Configuration of network bridge br0 using NetworkManager..
sudo nmcli con add type bridge con-name br0 ifname br0 ipv4.method auto ipv6.method disabled
sudo mcli con modify br0 bridge.stp no
sudo nmcli con add type ethernet slave-type bridge con-name bridge-slave-eno1 ifname eno1 master br0
sudo nmcli con delete "Wired Connection"
sudo nmcli con up br0

# Check the bridge status..
sudo ip a

# 2. Definition of libvirt network (XML file)..
sudo cat << EOF > br0-network.xml
<network>
  <name>br0-network</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

# 3. Creation and activation of libvirt network..
sudo virsh net-define br0-network.xml
sudo virsh net-start br0-network
sudo virsh net-autostart br0-network
sudo virsh net-list --all
