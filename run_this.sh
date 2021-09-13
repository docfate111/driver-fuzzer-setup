#!/bin/sh
cd /image
echo "for some reason can't run chroot in docker so i cant run create-image.sh in dockerfile"
chmod +x create-image.sh
./create-image.sh
cd ~
wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar -xf go1.14.2.linux-amd64.tar.gz
mv go goroot
mkdir gopath
export GOPATH=`pwd`/gopath
export GOROOT=`pwd`/goroot
export PATH=$GOPATH/bin:$PATH
export PATH=$GOROOT/bin:$PATH
go get -u -d github.com/google/syzkaller/prog
cd gopath/src/github.com/google/syzkaller/
make
echo "then bin/syz-manager gives errors: can't find /root/go/src/github.com/google/syzkaller/bin/linux_amd64/syz-fuzzer"
echo "to fix this we cp to /root/go"
mkdir -p /root/go/src/github.com/google/syzkaller
cp -r bin /root/go/src/github.com/google/syzkaller
./bin/syz-manager --config=/root/my.cfg --debug
