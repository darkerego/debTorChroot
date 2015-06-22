#!/bin/bash

function get_DEPS(){
sudo apt-get install libc6 libevent-2.0-5 libssl1.0.0 zlib1g lsb-base libssl-dev libevent-dev libnss3-1d-dbg
}

function conf_TOR(){
# Choose architecure. On 32 bit systems choose 'arch32', on 64 bit systems choose 'arch64'
arch64="x86_64-linux-gnu"
arch32="i386-linux-gnu"
arch=$arch32 # or $arch64


tar -xzvf tor-0.2.0.35.tar.gz
cd tor-0.2.6.9
./configure --prefix=/tor
make
sudo adduser --disabled-login --gecos "Tor user,,," tor
TORCHROOT=/home/tor/chroot
sudo mkdir -p $TORCHROOT
sudo make install prefix=$TORCHROOT/tor exec_prefix=$TORCHROOT/tor
sudo mkdir $TORCHROOT/lib
sudo cp `ldd $TORCHROOT/tor/bin/tor | awk '{print $3}'|grep "^/"` $TORCHROOT/lib
sudo cp /lib/$arch/libnss* /lib/$arch/libnsl* /lib/$arch/libresolv* /lib/$arch/libnss3.so /lib/$arch/libgcc_s.so.* $TORCHROOT/lib
sudo cp /usr/lib/$arch/libnss3.so $TORCHROOT/lib
sudo mkdir $TORCHROOT/dev
sudo mknod -m 644 $TORCHROOT/dev/random c 1 8
sudo mknod -m 644 $TORCHROOT/dev/urandom c 1 9
sudo mknod -m 666 $TORCHROOT/dev/null c 1 3
sudo sh -c "grep ^tor /etc/passwd > $TORCHROOT/etc/passwd"
sudo sh -c "grep ^tor /etc/group > $TORCHROOT/etc/group"
sudo cp /etc/nsswitch.conf /etc/host.conf /etc/resolv.conf /etc/hosts $TORCHROOT/etc
sudo cp /etc/localtime $TORCHROOT/etc
echo 'User tor' >> $TORCHROOT/tor/etc/tor/torrc
echo 'DataDirectory /var/lib/tor2' >> $TORCHROOT/tor/etc/tor/torrc
echo 'GeoIPFile /tor/share/tor/geoip' >> $TORCHROOT/tor/etc/tor/torrc
echo 'PidFile /var/run/tor/tor.pid' >> $TORCHROOT/tor/etc/tor/torrc
echo 'Log notice file /var/log/tor/log' >> $TORCHROOT/tor/etc/tor/torrc
echo 'RunAsDaemon 1' >> $TORCHROOT/tor/etc/tor/torrc
sudo mkdir -p $TORCHROOT/var/run/tor
sudo mkdir -p $TORCHROOT/var/lib/tor
sudo mkdir -p $TORCHROOT/var/lib/tor2
sudo mkdir -p $TORCHROOT/var/log/tor
sudo chown tor:tor $TORCHROOT/var/run/tor
sudo chown tor:tor $TORCHROOT/var/lib/tor
sudo chown tor:tor $TORCHROOT/var/lib/tor2
sudo chown tor:tor $TORCHROOT/var/log/tor
}

function make_TAR(){
sudo cp -R -p $TORCHROOT /tmp/tor-chroot
sudo tar -zcvf ~/tor-chroot.tar.gz /tmp/tor-chroot
}

echo 'Will now download tor source and check signature. For security reasons I leave it up to you to tell me if the signature checks out.'

wget https://dist.torproject.org/tor-0.2.6.9.tar.gz
wget https://dist.torproject.org/tor-0.2.6.9.tar.gz.asc
gpg --recv-key 8D29319A
gpg --verify tor-0.2.6.9.tar.gz.asc tor-0.2.6.9.tar.gz

read -p "Does the signature check out? [yn]" answer
if [[ $answer = y ]] ; then
	get_DEPS
	conf_TOR
	make_TAR
	echo "Done. Archive located at ~/tor-chroot.tar.gz"
else
	echo "Please check the signature and download manually."
fi


