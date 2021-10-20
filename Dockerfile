FROM ubuntu:focal

# setup build environment
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget bc build-essential git cmake pkg-config autoconf dh-autoreconf libglib2.0-dev libelf-dev libssl-dev cpio flex bison libjson-c-dev libpixman-1-dev libcapstone-dev golang clang-format python-is-python3 && \
	wget http://archive.ubuntu.com/ubuntu/pool/universe/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb && apt install -y ./dwarves_1.17-1_amd64.deb

# fetch sources
RUN git clone https://github.com/0xf4b1/bsod-kernel-fuzzing && cd bsod-kernel-fuzzing && git submodule init && git submodule update --depth=1 && cd kvm-vmi/kvm-vmi && git submodule init && git submodule update --depth=1 qemu

# build libkvmi
RUN cd /bsod-kernel-fuzzing/kvm-vmi/libkvmi && ./bootstrap && ./configure && make -j$(nproc) && make install

# build libvmi
RUN cd /bsod-kernel-fuzzing/kvm-vmi/libvmi && mkdir build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_KVM=ON -DENABLE_XEN=OFF -DENABLE_BAREFLANK=OFF && make -j$(nproc) && make install

# build qemu
RUN cd /bsod-kernel-fuzzing/kvm-vmi/kvm-vmi/qemu && ./configure --target-list=x86_64-softmmu --prefix=/usr/local && make -j$(nproc) && make install

# build bsod-afl
RUN cd /bsod-kernel-fuzzing/bsod-afl/AFLplusplus && make -j$(nproc) && \
    cd /bsod-kernel-fuzzing/bsod-afl && mkdir build && cd build && cmake .. && make && \
    cd /bsod-kernel-fuzzing/bsod-afl && git clone https://github.com/pwncollege/pwnkernel.git && cd pwnkernel && \
    git clone -b staging-testing git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/staging.git linux && \
    make -C linux defconfig && \
    echo "CONFIG_NET_9P=y" >> linux/.config && \
    echo "CONFIG_NET_9P_DEBUG=n" >> linux/.config && \
    echo "CONFIG_9P_FS=y" >> linux/.config && \
    echo "CONFIG_9P_FS_POSIX_ACL=y" >> linux/.config && \
    echo "CONFIG_9P_FS_SECURITY=y" >> linux/.config && \
    echo "CONFIG_NET_9P_VIRTIO=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_PCI=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_BLK=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_BLK_SCSI=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_NET=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_CONSOLE=y" >> linux/.config && \
    echo "CONFIG_HW_RANDOM_VIRTIO=y" >> linux/.config && \
    echo "CONFIG_DRM_VIRTIO_GPU=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_PCI_LEGACY=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_BALLOON=y" >> linux/.config && \
    echo "CONFIG_VIRTIO_INPUT=y" >> linux/.config && \
    echo "CONFIG_CRYPTO_DEV_VIRTIO=y" >> linux/.config && \
    echo "CONFIG_BALLOON_COMPACTION=y" >> linux/.config && \
    echo "CONFIG_PCI=y" >> linux/.config && \
    echo "CONFIG_PCI_HOST_GENERIC=y" >> linux/.config && \
    echo "CONFIG_GDB_SCRIPTS=y" >> linux/.config && \
    echo "CONFIG_DEBUG_INFO=y" >> linux/.config && \
    echo "CONFIG_DEBUG_INFO_REDUCED=n" >> linux/.config && \
    echo "CONFIG_DEBUG_INFO_SPLIT=n" >> linux/.config && \
    echo "CONFIG_DEBUG_FS=y" >> linux/.config && \
    echo "CONFIG_DEBUG_INFO_DWARF4=y" >> linux/.config && \
    echo "CONFIG_DEBUG_INFO_BTF=y" >> linux/.config && \
    echo "CONFIG_FRAME_POINTER=y" >> linux/.config && make -C linux -j64 bzImage && \
    wget -q -c https://busybox.net/downloads/busybox-1.32.0.tar.bz2 && \
    [ -e busybox-1.32.0 ] || tar xjf busybox-1.32.0.tar.bz2 && \
    make -C busybox-1.32.0 defconfig && \
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' busybox-1.32.0/linux/.config && \
    make -C busybox-1.32.0 -j16 && \
    make -C busybox-1.32.0 install && \
    cd fs && mkdir -p bin sbin etc proc sys usr/bin usr/sbin root home/ctf && cd .. && \
    cp -a busybox-1.32.0/_install/* fs && pushd fs && \
    find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz && \
    popd


# build bsod-syzkaller
RUN cd /bsod-kernel-fuzzing/bsod-syzkaller/syzkaller && make generate && make && cd /bsod-kernel-fuzzing/bsod-syzkaller/syz-bp-cov && make
