# !!! If created vm is using virtio, DO NOT qemu-system-x86_64 start without drive option "if=virtio", you will get BSOD
# The issue seems to be with the USB bus implementation in I440FX chipset that is emulated by qemu by default (details here). The workaround is emulating the ICH9 chipset instead. This is done by adding -M q35 parameter.
qemu-system-x86_64 -enable-kvm \
    -cpu host \
    -smp 4,sockets=1,cores=2,threads=2 \
    -M q35 \
    -m 8192 \
    -boot c \
    -drive file=~/D/vm/fs.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
    -usb -device usb-host,hostbus=1,hostaddr=6 \
    -vga qxl \
    # -drive file=/dev/sdc2,format=raw,if=virtio,cache=none,index=1 \
    # -device e1000,netdev=net0,mac=ED:BE:DA:EF:F4:9D -netdev tap,id=net0,script=~/kvm/qemu-ifup

################################################################################
