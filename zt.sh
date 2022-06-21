#!/bin/bash
#
# script to install and manage Zerotier on a Synology NAS
# will also migrate settings from the Synology spkg
# based on https://docs.zerotier.com/devices/synology/

set -eEuo pipefail

RC_SCRIPT=/usr/local/etc/rc.d/tun.sh
TUN_DEV=/dev/net/tun
DOCKER_VOLUME=/volume1/docker/zerotier-one
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE=zerotier/zerotier-synology:${DOCKER_IMAGE_VERSION:-latest}
DOCKER_CONTAINER=zerotier

function usage {
  cat <<EOF >&2
$(basename -- "$0") <command> [command options]

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

EOF

  exit 1
}

function invokeCommand {
  local -r cmdArgs=("$@")
  local -r cmd="cmd_${cmdArgs[0]}"
  local -r cmdOpts=("${cmdArgs[@]:1}")

  if [[ "$(type -t "$cmd")" == "function" ]] ; then
    "$cmd" "${cmdOpts[@]}"
  else
    cmd_zt_cli "$@"
  fi
}

function cmd_setup {
  # ref: https://memoryleak.dev/post/fix-tun-tap-not-available-on-a-synology-nas/
  if [ ! -f "$RC_SCRIPT" ] ; then
    cat <<EOF > "$RC_SCRIPT"
#!/bin/sh -e
if ! lsmod | grep -qw tun ; then
  insmod /lib/modules/tun.ko
fi
EOF
  fi

  if [ ! -x "$RC_SCRIPT" ] ; then
    chmod a+x "$RC_SCRIPT"
  fi

  "$RC_SCRIPT"

  if [ ! -r "$TUN_DEV" ] ; then
    echo ERROR "$TUN_DEV" not found >&2
    exit 1
  fi

  if ! command -v docker 2> /dev/null ; then
    echo ERROR Docker not installed. Attempting install... >&2
    if ! synopkg install_from_server Docker ; then
      echo ERROR Docker failed to install. Install manually >&2
      exit 2
    fi
  fi

  if [ ! -d "$DOCKER_VOLUME" ] ; then
    # TODO query Docker pkg volume root
    # shellcheck disable=SC2174
    mkdir -p -m 0700 "$DOCKER_VOLUME"
  fi

  if [ -d /var/lib/zerotier-one ] \
    && [ -r /var/lib/zerotier-one/identity.secret ] ; then
    # we have config from the Synology package
    if [ ! -r "$DOCKER_VOLUME/identity.secret" ] ; then
      echo Found config in /var/lib/zerotier-one
      echo Copying to Docker volume
      cp -av /var/lib/zerotier-one/* "$DOCKER_VOLUME/"
    fi
  fi

  cmd_start
}

function cmd_start {
  docker run -d           \
    --name "$DOCKER_CONTAINER" \
    --restart=always      \
    --device="$TUN_DEV" \
    --net=host            \
    --cap-add=NET_ADMIN   \
    --cap-add=SYS_ADMIN   \
    -v "$DOCKER_VOLUME":/var/lib/zerotier-one "$DOCKER_IMAGE"
}

function cmd_stop {
  local -r cid="$(docker ps -q -f name="$DOCKER_CONTAINER")"

  if [ -n "$cid" ] ; then
    docker stop "$cid"
  fi
}

function cmd_upgrade {
  # download first
  docker pull "$DOCKER_IMAGE"

  cmd_stop
  docker container rm "$DOCKER_CONTAINER"
  cmd_start
}

function cmd_in_docker {
  docker exec -it "$DOCKER_CONTAINER" "$@"
}

function cmd_zt_cli {
  cmd_in_docker zerotier-cli "$@"
}

function cmd_shell {
  cmd_in_docker bash "$@"
}

case "${#@}" in
  0)
    usage
    ;;
  *)
    invokeCommand "$@"
    ;;
esac
