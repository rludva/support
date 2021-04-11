# Change LogLevel of masters
* Set DEBUG_LOGLEVEL to 8 in /etc/origin/master/master.env

# Restart api, controller.
$ /usr/local/bin/master-restart api api
$ /usr/local/bin/master-restart controllers controllers


# Gather logs for few minutes minutes:
$ /usr/local/bin/master-logs controllers controllers  &> /tmp/controllers.logs
$ /usr/local/bin/master-logs api api  &> /tmp/api.logs
