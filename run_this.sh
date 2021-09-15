#!/bin/sh
cd /image
echo "for some reason can't run chroot in docker so i cant run create-image.sh in dockerfile"
chmod +x create-image.sh
./create-image.sh
cd ~
wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar -xf go1.14.2.linux-amd64.tar.gz
mv go goroot
export GOPATH=`pwd`/gopath
export GOROOT=`pwd`/goroot
export PATH=$GOPATH/bin:$PATH
export PATH=$GOROOT/bin:$PATH
go get -u -d github.com/google/syzkaller/prog
cd gopath/src/github.com/google/syzkaller/
cp ~/fs_ioctl_f2fs.txt .
make bin/syz-extract
./bin/syz-extract -os linux -arch=amd64 -sourcedir /kernel -build fs_ioctl_f2fs.txt
make
./bin/syz-manager --config=/root/my.cfg
