# Zerotier Synology Docker script

Script to install and manage Zerotier on a Synology NAS.
`setup` will also migrate settings from the Synology spkg

based on https://docs.zerotier.com/devices/synology/

Usage:
```
zt.sh <command> [command options]

  Custom commands:
  setup
  start
  stop
  upgrade
  shell [shell command] [shell args]

  everything else is passed through to the zerotier-one cli inside the Docker container
  eg.
  info
  status
  join <network id>
  -j listnetworks
```
