#make-tor-chroot

Scripted from <a href="https://trac.torproject.org/projects/tor/wiki/doc/TorInChroot">torproject.org's chroot instructions</a>, 
this is a shell script for Ubuntu systems (although it may also work on Debian systems) that builds and configures a 
chrooted tor daemon. It's no longer necessary to specify the architecture, as the script now does that for you. The 
chroot will end up in /home/tor/chroot, and a user ("tor") will be added to the system. The configuration of the torrc 
file is automated as well, so after running this script you can just go ahead and start tor:

echo "TORCHROOT=/home/tor/chroot" >> ~/.bashrc
sudo chroot $TORCHROOT /tor/bin/tor

#Usage

./make-tor-chroot.sh  <[[ --gen-tor | gen-tar | gen-all ]]>
  * --gen-tor : Just generate the chroot & build tor
  * --gen-tar : Generate a tar archive & hashsums from the generated chroot
  * --gen-all : Do both of these things
  
