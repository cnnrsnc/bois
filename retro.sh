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

mount -o rw,remount /boot

endlines="sharedevice=NETWORK\nsharenetwork_cmd1=if [ ! -d /dev/net ]; then mkdir -p /dev/net; mknod /dev/net/tun c 10 200; chmod 600 /dev/net/tun; fi \&\& /userdata/tailscale/tailscaled -state /userdata/tailscale/state > /userdata/tailscale/tailscaled.log 2>\&1 \& sleep 2s; /userdata/tailscale/tailscale up --accept-routes\nsharenetwork_nfs1=ROMS@truenas-scale:/mnt/pool/retro/roms\nsharenetwork_nfs2=CHEATS@truenas-scale:/mnt/pool/retro/cheats"

sed -i -z -e "s|sharedevice=INTERNAL|$endlines|" /boot/batocera-boot.conf
