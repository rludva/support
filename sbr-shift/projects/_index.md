# Project dump

## Get sosreport:
```bash
$ sosreport -e docker -k docker.all=off -k docker.logs=off
```

## Get a project dump where you're having issues:
```bash
$ curl -LO https://raw.githubusercontent.com/nekop/shiftbox/master/oc-dump
$ chmod +x ./oc-dump
$ ./oc-dump PROJECT_with_issues
```
