#!/bin/bash
# DebTorChrootGen
# Author DarkerEgo
# A shell script for ubuntu-esc systems that compiles tor in a chroot.
# Also can create a tar.gz archive to be extracted on other systems for 
# a portable, chrooted tor daemon.

usage(){
echo "▄▄▄▄▄      ▄▄▄   ▄▄·  ▄ .▄▄▄▄             ▄▄▄▄▄ ▄▄ • ▄▄▄ . ▐ ▄ ";
echo "•██  ▪     ▀▄ █·▐█ ▌▪██▪▐█▀▄ █·▪     ▪    •██  ▐█ ▀ ▪▀▄.▀·•█▌▐█";
echo " ▐█.▪ ▄█▀▄ ▐▀▀▄ ██ ▄▄██▀▐█▐▀▀▄  ▄█▀▄  ▄█▀▄ ▐█.▪▄█ ▀█▄▐▀▀▪▄▐█▐▐▌";
echo " ▐█▌·▐█▌.▐▌▐█•█▌▐███▌██▌▐▀▐█•█▌▐█▌.▐▌▐█▌.▐▌▐█▌·▐█▄▪▐█▐█▄▄▌██▐█▌";
echo " ▀▀▀  ▀█▄▀▪.▀  ▀·▀▀▀ ▀▀▀ ·.▀  ▀ ▀█▄▀▪ ▀█▄▀▪▀▀▀ ·▀▀▀▀  ▀▀▀ ▀▀ █▪";

echo " Usage: $0 [[--build|-b | --configure|-c | --archive|-a"
echo "[[ ---------------------------------------------------------- ]]"
echo "[[    --generate |-g : Build tor chroot, configure, archive   ]]"
echo "[[    --build    |-b : Compile tor in chroot, add tor user    ]]"
echo "[[    --configure|-c : Configure chroot torrc file defaults   ]]"
echo "[[    --archive  |-a : Generate tar gz achive and hashsums    ]]"
echo "[[ ---------------------------------------------------------- ]]"

}

getDeps(){
sudo apt-get install libc6 libevent-2.0-5 libssl1.0.0 zlib1g lsb-base libssl-dev libevent-dev libnss3-1d-dbg
wget https://www.torproject.org/dist/tor-0.2.6.10.tar.gz
wget https://www.torproject.org/dist/tor-0.2.6.10.tar.gz.asc
gpg --recv-key 8D29319A
gpg --verify tor-0.2.6.10.tar.gz.asc tor-0.2.6.10.tar.gz
}
 
makeTor(){


# determine arch
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
# where libs are stored on ubuntu depending on arch
arch64="x86_64-linux-gnu"
arch32="i386-linux-gnu"
if [[ $ARCH == "64" ]];then
	arch=$arch64
elif [[ $ARCH == "32" ]];then
	arch=$arch32
else
	echo "Unknown architecture? Quitting!"
	exit1
fi

# build tpr
tar -xzvf tor-*.gz
cd tor*
./configure --prefix=/tor
make
# add chroot user
sudo adduser --disabled-login --gecos "Tor user,,," tor
TORCHROOT=/home/tor/chroot
# copy required libs to chroot
sudo mkdir -p $TORCHROOT
sudo make install prefix=$TORCHROOT/tor exec_prefix=$TORCHROOT/tor
sudo mkdir $TORCHROOT/lib64
sudo mkdir $TORCHROOT/lib
sudo cp /lib64/ld-linux-x86-64.so.2 $TORCHROOT/lib64/
sudo cp `ldd $TORCHROOT/tor/bin/tor | awk '{print $3}'|grep "^/"` $TORCHROOT/lib
sudo cp /lib/$arch/libnss* /lib/$arch/libnsl* /lib/$arch/libresolv* /usr/lib/$arch/libnss3.so /lib/$arch/libgcc_s.so.* $TORCHROOT/lib
sudo cp /usr/lib/$arch/libnss3.so $TORCHROOT/lib
sudo mkdir $TORCHROOT/dev
sudo mkdir $TORCHROOT/etc
sudo mknod -m 644 $TORCHROOT/dev/random c 1 8
sudo mknod -m 644 $TORCHROOT/dev/urandom c 1 9
sudo mknod -m 666 $TORCHROOT/dev/null c 1 3
# copy system configs to chroot
sudo sh -c "grep ^tor /etc/passwd > $TORCHROOT/etc/passwd"
sudo sh -c "grep ^tor /etc/group > $TORCHROOT/etc/group"
sudo cp /etc/nsswitch.conf /etc/host.conf /etc/resolv.conf /etc/hosts $TORCHROOT/etc/
sudo cp /etc/localtime $TORCHROOT/etc
# default torrc file
sudo cp $TORCHROOT/tor/etc/tor/torrc.sample $TORCHROOT/tor/etc/tor/torrc


sudo mkdir -p $TORCHROOT/var/run/tor
sudo mkdir -p $TORCHROOT/var/lib/tor
sudo mkdir -p $TORCHROOT/var/lib/tor2
sudo mkdir -p $TORCHROOT/var/log/tor
#sudo mkdir -p $TORCHROOT/var/srv
#sudo chown tor:tor $TORCHROOT/var/srv
sudo chown tor:tor $TORCHROOT/var/run/tor
sudo chown tor:tor $TORCHROOT/var/lib/tor
sudo chown tor:tor $TORCHROOT/var/lib/tor2
sudo chown tor:tor $TORCHROOT/var/log/tor
}


confTorrc(){
# create a basic torrc file to get up and running
cat <<EOF > /tmp/torrc
User tor
DataDirectory /var/lib/tor2
GeoIPFile /tor/share/tor/geoip
PidFile /var/run/tor/tor.pid
Log notice file /var/log/tor/log
EOF
sudo cp /tmp/torrc $TORCHROOT/tor/etc/tor/torrc
sleep 1
# Either start from init.d or from chroot
read -p "Install init scripts? If not you will have to start/stop tor manually through chroot (y/n)" initYn
if [[ $initYn == "y" ]];then
    echo "Downloading and installing the init scripts..."
    sudo wget -O /etc/init.d/tor http://www.cl.cam.ac.uk/users/sjm217/projects/tor/tor.init
    sudo wget -O /etc/default/tor http://www.cl.cam.ac.uk/users/sjm217/projects/tor/tor.default
    sudo wget -O $TORCHROOT/tor/bin/tor-chroot http://www.cl.cam.ac.uk/users/sjm217/projects/tor/tor-chroot
    sudo chmod 755 /etc/init.d/tor /etc/default/tor $TORCHROOT/tor/bin/tor-chroot
    echo "Done"
else
# if manual, may as well add an alias for TORCHROOT
    echo "Adding torchroot alias to your bashrc file. Start tor with 'sudo chroot $TORCHROOT /tor/bin/tor'"
    echo $TORCHROOT=/home/tor/chroot >> .bashrc
    source .bashrc
fi
}

genTz(){
# pack an archive and you have a portable, chrootable tor daemon!
TORCHROOT=/home/tor/chroot
cwd=$(pwd)
dest=$cwd/tor-chroot
mkdir $dest
sudo tar -zcvf $dest/tor-chroot.tar.gz /home/tor/chroot
sha512sum $dest/tor-chroot.tar.gz > $dest/tor-chroot.tar.gz.sha512
sha1sum $dest/tor-chroot.tar.gz > $dest/tor-chroot.tar.gz.sha1
md5sum $dest/tor-chroot.tar.gz > $dest/tor-chroot.tar.gz.md5
echo "For a portable(ish, root probably required) tor daemon," 
echo "extract tar archive on another system and run."
}


# handle command line options

case "$1" in
 --generate|-g) echo "Building tor chroot, configuring torrc, and making tar with hashsums."
    getDeps
    echo "Starting compilation process..."
    makeTor
    echo  "Generating and adding torrc file..."
    confTorrc
    echo  "Generating a tar.gz archive and hashsums..."
    genTz
    echo "Done!"
;;
 --build|-b)  echo "Getting source and dependencies..."
    getDeps
    echo "Starting compilation process..."
    makeTor
;;
 --configure|-c)  echo  "Generating and adding torrc file..."
    confTorrc
;;
 --archive|-a) echo  "Generating a tar.gz archive and hashsums..."
    genTz
;;
      *) echo "Invalid or no option..."
    usage
;;
esac

exit
