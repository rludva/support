# Example of SSHD Attack log from sshd.service


## Data and logs

### journalctl-sshd.log
- Example from sshd.service logs on system which has world wide access to port 22/tcp (ssh)

```log
Dec 19 18:47:33 bastion.local.nutius.com sshd-session[57836]: Received disconnect from 103.117.57.134 port 37456:11: Bye Bye [preauth]
Dec 19 18:47:33 bastion.local.nutius.com sshd-session[57836]: Disconnected from invalid user opengts 103.117.57.134 port 37456 [preauth]
Dec 19 18:47:42 bastion.local.nutius.com sshd[54502]: drop connection #1 from [111.19.212.140]:60052 on [192.168.0.32]:22 penalty: exceeded LoginGraceTime
Dec 19 18:48:02 bastion.local.nutius.com sshd[54502]: drop connection #1 from [111.19.212.140]:54160 on [192.168.0.32]:22 penalty: exceeded LoginGraceTime
Dec 19 18:48:22 bastion.local.nutius.com sshd[54502]: drop connection #1 from [111.19.212.140]:58200 on [192.168.0.32]:22 penalty: exceeded LoginGraceTime
Dec 19 18:48:41 bastion.local.nutius.com sshd[54502]: drop connection #1 from [111.19.212.140]:41506 on [192.168.0.32]:22 penalty: exceeded LoginGraceTime
Dec 19 18:49:02 bastion.local.nutius.com sshd[54502]: drop connection #1 from [111.19.212.140]:49880 on [192.168.0.32]:22 penalty: exceeded LoginGraceTime
Dec 19 18:49:11 bastion.local.nutius.com sshd[54502]: Timeout before authentication for connection from 45.78.198.89 to 192.168.0.32, pid = 57833
```


### blacklist.txt
- List of IP addresses collected from bastion host and `journalctl -u sshd`.


### users.txt
- List of users that are used to access and attack through ssh on bastion host.
- Extracted from `journalctl -u sshd`

```log
Dec 19 18:52:42 bastion.local.nutius.com sshd-session[57843]: Connection closed by 45.78.198.89 port 34390 [preauth]
Dec 19 18:53:42 bastion.local.nutius.com sshd-session[58033]: Invalid user ftpuser from 45.78.198.89 port 43642
Dec 19 18:53:43 bastion.local.nutius.com sshd-session[58033]: Received disconnect from 45.78.198.89 port 43642:11: Bye Bye [preauth]
Dec 19 18:53:43 bastion.local.nutius.com sshd-session[58033]: Disconnected from invalid user ftpuser 45.78.198.89 port 43642 [preauth]
Dec 19 18:56:08 bastion.local.nutius.com sshd-session[58366]: Connection closed by 45.78.198.89 port 46462 [preauth]
```


## Scripts

### create-ipset-blacklist.sh
- This script adds blacklist ipset and its is assigned to drop zone in firewall.

### block-ip.sh
- Adds IP addreess to the blacklist ipset
- The IP address is set via argument

### build-blacklist.sh
- Build list of IP addresses thats try to attack with logging attempts to port 22/tcp (sshd)
- Creates `blacklist.txt` file with these IPs
- Can be executed multiple time and if IP is not present in the `blacklist.txt` it is added

### bulk-block.sh
- Adds all IPS listed in `blacklist.txt` to the blacklist ipset using the `block-ip.sh` sript.

### extract-user.sh
- Extract users that are used to login to the system into a table.

### get-entries-blacklist.sh
- Lists content of blacklist ipset entries.

### get-entries-whitelist.sh
- Lists content of whitelist ipset entries.
