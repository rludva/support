#!/bin/bash

# Show the drop zone details..
#sudo firewall-cmd --zone=drop --list-all

# Show all entries in the whitelist ipset..
sudo firewall-cmd --ipset=whitelist --get-entries

# Alternative:
#sudo nft list set inet firewalld whitelist
