#! /bin/bash -ex
cd $1
pwd

RPI_SRC=dhcpcd5_8.1.2-1+rpt9.debian.tar.xz
UP_SRC=dhcpcd-9.4.1.tar.xz
NEW_SRC=dhcpcd5-9.4.1

# We need uupdate, that pulls in a ton of crap, oh well, hope not to need to run this too many times
sudo apt-get update
sudo apt-get install -y devscripts libudev-dev

# Fix-up stuff not properly installed by sensorgnome-dockcross
for f in libudev.h; do
  sudo ln -s /usr/include/$f /usr/xcc/armv7-unknown-linux-gnueabi/armv7-unknown-linux-gnueabi/sysroot/usr/include/
done

# Download Raspberry Pi's dhcpcd5 source package
wget -nv http://archive.raspberrypi.org/debian/pool/main/d/dhcpcd5/$RPI_SRC
mkdir dhcpcd5-old
tar -C dhcpcd5-old -Jxf $RPI_SRC

# Download upstream source package
wget -nv -O $UP_SRC https://roy.marples.name/downloads/dhcpcd/$UP_SRC

# Update the rPi sources with the upstream
cd dhcpcd5-old
echo "yes" | uupdate --verbose ../$UP_SRC

# Build the resulting new package
cd ../$NEW_SRC
# need some hacks so dpkg-buildpackage succeeds
( cd  /usr/xcc/armv7-unknown-linux-gnueabi/bin;
  for f in objcopy objdump strip; do sudo ln -s armv7-unknown-linux-gnueabi-$f arm-linux-gnueabihf-$f; done;
)
# need to disable tests -- the github runner can't run the armhf executables
export DEB_BUILD_OPTIONS=nocheck
#
# echo dpkg-buildpackage -us -uc -nc -d --target-arch armhf -a armhf --target-type armv7-unknown-linux-gnueabi
# bash -i
#
dpkg-buildpackage -us -uc -nc -d --target-arch armhf -a armhf --target-type armv7-unknown-linux-gnueabi

cp ../${NEW_SRC/-/_}*.deb ../../packages
