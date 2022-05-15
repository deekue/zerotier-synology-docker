# Zerotier Synology Docker script

<abbr title="Quick and Dirty">QaD</abbr> script to install and manage Zerotier on a Synology NAS.

based on https://docs.zerotier.com/devices/synology/

Usage:
```
zt.sh <command> [command options]

Custom commands:
  setup
  start
  upgrade
  docker [docker command] [docker args]
  shell

everything else is passed through to the zerotier-one cli inside the Docker container
  eg.
  info
  status
  join <network id>
```
