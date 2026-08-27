#!/bin/bash

cd $HOME

arch=$(uname -m)

[[ "$arch" == "x86_64" ]] && arch="amd64" || arch="arm64"

HostName="${HN:-retro}"

wget https://pkgs.tailscale.com/stable/tailscale_1.102.3_$arch.tgz

package=$(ls ./*tgz)

tar -xzf $package

ts=${package%.tgz}

mv $ts /userdata/tailscale

/userdata/tailscale/tailscaled -state /userdata/tailscale/state > /userdata/tailscale/tailscaled.log 2>&1 &

/userdata/tailscale/tailscale up --auth-key "tskey-auth-kg9MW1TGRq11CNTRL-rHwcB9aCmf22AcD7thvgf2nHTDF7mqhw"

mount -o rw,remount /boot

sed -i 's|INTERNAL|NETWORK|' /boot/batocera-boot.conf

endlines="
sharenetwork_cmd1=eval if [ ! -d /dev/net ]; then mkdir -p /dev/net; mknod /dev/net/tun c 10 200; chmod 600 /dev/net/tun; fi && /userdata/tailscale/tailscaled -state /userdata/tailscale/state > /userdata/tailscale/tailscaled.log 2>&1 & sleep 2s; /userdata/tailscale/tailscale up --accept-routes
sharenetwork_nfs1=ROMS@100.0.0.1:/mnt/Documents/batocera/roms
sharenetwork_nfs2=SAVES@100.0.0.1:/mnt/Documents/batocera/saves
sharenetwork_nfs3=BIOS@100.0.0.1:/mnt/Documents/batocera/bios"

echo "$endlines" >> /boot/batocera-boot.conf
