#!/bin/bash

# https://developer.fedoraproject.org/tech/database/postgresql/about.html
sudo dnf install -y postgresql postgresql-server
sudo postgresql-setup --initdb --unit postgresql
sudo systemctl start postgresql
sudo su - postgres
createuser workspaces -P
createdb quick-start
> psql -d quick-start
