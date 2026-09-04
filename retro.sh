#!/bin/bash

cd $HOME

if [ ! -d /userdata/tailscale ]; then

    arch=$(uname -m)

    [[ "$arch" == "x86_64" ]] && arch="amd64" || arch="arm64"

    HostName="${HN:-retro}"

    wget https://pkgs.tailscale.com/stable/tailscale_1.102.3_$arch.tgz

    package=$(ls ./*tgz)

    tar -xzf $package

    ts=${package%.tgz}

    mv $ts /userdata/tailscale

    /userdata/tailscale/tailscaled -state /userdata/tailscale/state > /userdata/tailscale/tailscaled.log 2>&1 &

    /userdata/tailscale/tailscale up --auth-key "$AUTHKEY" --accept-routes

fi

sed -i "s|hostname=BATOCERA|hostname=${HostName}|" /userdata/system/batocera.conf

hostname $HostName

mkdir /nas

mkdir ./services

cat << EOF > /userdata/system/services/nas_mount                                                                                                         
log=$HOME/serlog


case $1 in
  "start")
    [ -d /userdata/system/nas ] || mkdir /userdata/system/nas

    /userdata/tailscale/tailscaled -state /userdata/tailscale/state > /userdata/tailscale/tailscaled.log 2>&1 &
    echo "Tailscale daemon exit code and PID: ${?} $(pgrep tailscaled)" >> $log

    /userdata/tailscale/tailscale up --accept-routes --accept-dns
    echo "Tailscale up exit code: ${?}" >> $log

    tsip=$(/userdata/tailscale/tailscale ip | head -n 1)

    ip addr | grep $tsip || ip addr add ${tsip}/32 dev tailscale0

    mount -t nfs -o hard,retrans=3,timeo=100 truenas-scale:/mnt/pool/retro /nas
    mount | grep nas >> $log
  ;;
  "stop")
    rm $log
    umount  /nas
    /userdata/tailscale/tailscale down
    pkill tailscaled
  ;;
esac

EOF
batocera-services enable nas
rm $package
reboot
