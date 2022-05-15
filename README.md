# Zerotier Synology Docker script

<abbrev alt="Quick and Dirty">QaD</abbrev> script to install and manage Zerotier on a Synology NAS.

based on https://docs.zerotier.com/devices/synology/

Usage:
<quote>
zt.sh &lt;command&gt; [command options]

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
  join &lt;network id&gt;
</quote>
