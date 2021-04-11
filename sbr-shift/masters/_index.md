# Change LogLevel of masters
* Set DEBUG_LOGLEVEL to 8 in /etc/origin/master/master.env
  (the default log level is 2)


```bash
$ sudo cat /etc/origin/master/master.env

# Proxy configuration
# See https://docs.openshift.com/container-platform/latest/install_config/http_proxies.html#configuring-hosts-for-proxies-using-ansible

DEBUG_LOGLEVEL=2
```


## Restart api, controller.
```bash
$ /usr/local/bin/master-restart api api
$ /usr/local/bin/master-restart controllers controllers
```


## Gather logs for few minutes minutes:
```bash
$ /usr/local/bin/master-logs controllers controllers  &> /tmp/controllers.logs
$ /usr/local/bin/master-logs api api  &> /tmp/api.logs
```
