# How to use playbooks

## Download artifactories for offline usage
Use this playbook to download binaries and source code for defined releases and architectures of prometheus, alertmanager or node_exporter.

```bash
$ ansible-playbook artifactory.yaml -e "application=prometheus"
$ ansible-playbook artifactory.yaml -e "application=alertmanager"
```
## Install applications
```bash
$ ansible-playbook prometheus.yaml
$ ansible-playbook alertmanager.yaml
$ ansible-playbook node_exporter.yaml

```
