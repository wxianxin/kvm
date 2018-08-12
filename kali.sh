qemu-system-x86_64 -enable-kvm \
    -cpu host \
    -smp 4,sockets=1,cores=2,threads=2 \
    -M q35 \
    -m 8192 \
    -drive file=~/D/vm/kali.qcow2,format=qcow2,if=virtio,index=0 \
    -drive file=/home/coupe/kali-linux-2018.2-amd64.iso,media=cdrom \
    -vga qxl \
    -usb -device usb-host,hostbus=1,hostaddr=9 \
    # -net nic \

################################################################################
# sudo ip link add br0 type bridge
# sudo ip link set eth0 master br0
