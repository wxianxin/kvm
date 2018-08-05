qemu-system-x86_64 -enable-kvm \
    -cpu host \
    -smp 8,sockets=1,cores=4,threads=2 \
    -m 8192 \
    -drive file=~/D/vm/kali.qcow2,format=qcow2 \
    -usb -device usb-host,hostbus=1,hostaddr=6 \
    -vga qxl \

################################################################################
# sudo ip link add br0 type bridge
# sudo ip link set eth0 master br0
