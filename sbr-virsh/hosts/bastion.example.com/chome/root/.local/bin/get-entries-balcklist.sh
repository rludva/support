#!/bin/bash

# Show the drop zone details..
#sudo firewall-cmd --zone=drop --list-all

# Show all entries in the blacklist ipset..
sudo firewall-cmd --ipset=blacklist --get-entries

# Alternative:
#sudo nft list set inet firewalld blacklist

