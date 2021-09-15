FROM ubuntu:18.04

ENV GCC /usr
ENV KERNEL /kernel 
ENV IMAGE /image

RUN apt-get update && \
    apt-get -y install vim subversion build-essential flex bison libc6-dev libc6-dev-i386 \
                       linux-libc-dev libgmp3-dev libmpfr-dev libmpc-dev git debootstrap qemu-kvm \
                       libelf-dev libssl-dev bc qemu debootstrap sudo && \
                       cd ~ && \
		       wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz && \
		       tar -xf go1.14.2.linux-amd64.tar.gz && \
		       mv go goroot && \
                       mkdir gopath && \
     apt-get update && \
        apt-get install -y -q libc6-dev-i386 linux-libc-dev \
                gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi gcc-powerpc64le-linux-gnu gcc-mips64el-linux-gnuabi64 || true && \
        apt-get install -y -q g++-aarch64-linux-gnu || true && \ 
        apt-get install -y -q g++-powerpc64le-linux-gnu || true && \
        apt-get install -y -q g++-arm-linux-gnueabi || true && \
        apt-get install -y -q g++-mips64el-linux-gnuabi64 || true && \ 
        apt-get install -y -q g++-s390x-linux-gnu g++-riscv64-linux-gnu g++ && \
        [ -z "$(shell which python)" -a -n "$(shell which python3)" ] && sudo apt-get install -y -q python-is-python3 && \
        apt-get install -y -q clang-tidy clang clang-format ragel && \
        GO111MODULE=off go get -u golang.org/x/tools/cmd/goyacc && \
	cd ~ && \
	git clone https://github.com/google/syzkaller.git


ENV GOPATH /root/gopath
ENV GOROOT /root/gopath
ENV PATH ${GOPATH}/bin:${PATH}
ENV PATH ${GOROOT}/bin:${PATH}

RUN git clone -b staging-testing git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/staging.git /kernel

RUN mkdir -p /image && \
    ( cd /image && \
    wget https://raw.githubusercontent.com/google/syzkaller/master/tools/create-image.sh -O create-image.sh )

#RUN cd /root && /usr/local/go/bin/go get -u -d github.com/google/syzkaller/prog && \
#	 ( cd $HOME/go/src/github.com/google/syzkaller && NCORE=4 make )

# Compile linux kernel
# Docker handles echo so no "-e" needed
RUN ( cd /kernel      && \
    make defconfig   && \
    make kvm_guest.config && \
    echo "CONFIG_KCOV=y\nCONFIG_DEBUG_INFO=y\nCONFIG_KASAN=y\nCONFIG_KASAN_INLINE=y\nCONFIG_CONFIGFS_FS=y\nCONFIG_SECURITYFS=y\n" >> .config && \
    cp .config .config.bk && \
    make CC=/usr/bin/gcc oldconfig && \
    make CC=/usr/bin/gcc -j4 && \
    test -f /kernel/vmlinux && \
    test -f /kernel/arch/x86/boot/bzImage )

WORKDIR /root

COPY my.cfg .
COPY run_this.sh .
COPY fs_ioctl_f2fs.txt .
