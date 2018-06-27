# !!! If created vm is using virtio, DO NOT qemu-system-x86_64 start without drive option "if=virtio", you will get BSOD
qemu-system-x86_64 -enable-kvm \
    -cpu host \
    -smp cores=2,threads=2,sockets=1 \
    -m 8192 \
    -boot c \
    -drive file=/home/xx/vm/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
    -drive file=/dev/nvme0n1p5,format=raw,if=virtio,cache=none,index=1 \
    # -vnc :1
    # boot from iso
    # -boot d \
    # -drive file=/home/coupe/L/Downloads/Windows.iso,media=cdrom \
    # -drive file=/home/coupe/Downloads/virtio-win-0.1.141.iso,media=cdrom \


# qemu-system-x86_64 -M pc -cpu host -smp cores=2,threads=1,sockets=1 -drive file=/dev/sda6,if=virtio,cache=none,index=0 -drive file=/dev/sdb,if=virtio,cache=none,index=1 -cdrom /dev/cdrom -pidfile ./qemu-garak.pid -boot c -k de -m 4096 -smp 1 -device pci-assign,host=01:05.0 -daemonize -usb -usbdevice "tablet" -name garak -net nic,vlan=0,model=virtio,macaddr=02:01:01:01:01:01 -net tap,vlan=0,ifname=virtnet1,script=/etc/qemu-ifup,downscript=/etc/qemu-ifup -vnc :1
