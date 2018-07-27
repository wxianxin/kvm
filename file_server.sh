# !!! If created vm is using virtio, DO NOT qemu-system-x86_64 start without drive option "if=virtio", you will get BSOD
qemu-system-x86_64 -enable-kvm \
    -cpu host \
    -smp 8,sockets=1,cores=4,threads=2 \
    -m 8192 \
    -drive file=~/D/vm/fs.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
    -usb -device usb-host,hostbus=1,hostaddr=15 \
    -vga qxl \
    -net nic \
    # -drive file=/dev/nvme0n1p5,format=raw,if=virtio,cache=none,index=1 \
    # -device e1000,netdev=net0,mac=ED:BE:DA:EF:F4:9D -netdev tap,id=net0,script=~/kvm/qemu-ifup

################################################################################
# sudo ip link add br0 type bridge
# sudo ip link set eth0 master br0
    # -device e1000,netdev=net0,mac=DE:AD:BE:EF:F4:9D -netdev tap,id=net0,script=/home/coupe/kvm/qemu-ifup \
