#!/bin/bash

# Create ipset..
# --permanent: change is permanent (it will persist after firewalld restart)
# --new-ipset=blacklist: creates an IP set named 'blacklist'
# --type=hash:ip: set type is IP address (hash:ip)
# 💡 Note: The IP set is currently empty, so it does not block any IP yet.
sudo firewall-cmd --permanent --new-ipset=blacklist --type=hash:ip

# Connect the new ipset with drop zone..
# Assigns the IP set 'blacklist' to the drop zone, so all IPs in the set will be automatically dropped (firewall discards their packets)
# However, if the set is empty, nothing is blocked.
sudo firewall-cmd --permanent --zone=drop --add-source=ipset:blacklist

# Add IP to the ipset blacklist..
# BLOCK_IP="1.2.3.4"
# sudo firewall-cmd --permanent --ipset=blacklist --add-entry=$BLOCK_IP
# sudo firewall-cmd --ipset=blacklist --add-entry=$BLOCK_IP

# Create whitelist ipset..
sudo firewall-cmd --permanent --new-ipset=whitelist --type=hash:ip
sudo firewall-cmd --permanent --add-rich-rule='rule priority="-100" family="ipv4" source ipset="whitelist" accept'
# BLOCK_IP="1.2.3.4"
# sudo firewall-cmd --permanent --ipset=whitelist --add-entry=$BLOCK_IP
# sudo firewall-cmd --ipset=whitelist --add-entry=$BLOCK_IP


# Reload firewalld service
sudo firewall-cmd --reload

# Print the ipsets..
sudo firewall-cmd --get-ipsets

# Show ipset blacklist entries..
sudo firewall-cmd --ipset=blacklist --get-entries