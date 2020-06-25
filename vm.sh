# qemu-img create -f qcow2 ~/D/vm/kvm_win10.qcow2 40G

# unbind driver after bootup process
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/devices/0000:01:00.2/driver/unbind'
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/drivers/vfio-pci/bind'

# Standard locations from the Ubuntu `ovmf` package; last one is arbitrary:
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp

cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
taskset 0xFFF0 qemu-system-x86_64 \
  -drive if=pflash,format=raw,readonly,file=$VGAPT_FIRMWARE_BIN \
  -drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  -enable-kvm \
  -machine q35,accel=kvm,mem-merge=off \
  -cpu host,kvm=off,hv_vendor_id=vgaptrocks,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp 12,sockets=1,cores=6,threads=2 \
  -m 16384 \
  -mem-prealloc \
  -mem-path /dev/hugepages \
  -vga none \
  -rtc base=localtime \
  -boot menu=on \
  -acpitable file=/home/coupe/kvm/SSDT1.dat \
  -device vfio-pci,host=01:00.0,romfile=/home/coupe/kvm/TU106.rom \
  -device vfio-pci,host=01:00.1 \
  -device vfio-pci,host=01:00.2 \
  -device vfio-pci,host=01:00.3 \
  -drive file=/dev/nvme0n1p7,format=raw,if=virtio,cache=none,index=0 \
  -drive file=/dev/nvme1n1p4,format=raw,if=virtio,cache=none,index=1 \
  -usb -device usb-host,hostbus=3,hostaddr=2 \
  -usb -device usb-host,hostbus=3,hostaddr=3 \
  -usb -device usb-host,hostbus=5,hostaddr=3 \
;


# taskset 0xFFF0 qemu-system-x86_64 \
# -m 16384 \
# -m 16384 -mem-prealloc -mem-path /dev/hugepages \
# -vga none \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/TU106.rom \
# -drive file=/dev/sda,format=raw,if=virtio,cache=none,index=1 \
# -drive file=/home/coupe/D/vm/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
# -drive file=/home/coupe/D/vm/Win10_2004_English_x64.iso,media=cdrom \
# -drive file=/home/coupe/D/vm/virtio-win-0.1.171.iso,media=cdrom \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/navi_10.rom \
# -net nic,model=virtio \
