# qemu-img create -f qcow2 ~/D/vm/kvm_win10.qcow2 40G

# unbind driver after boot process
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/devices/0000:01:00.2/driver/unbind'
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/drivers/vfio-pci/bind'

# sudo bash /home/coupe/kvm/bind_vfio.sh
sudo bash /home/coupe/kvm/set_cpu_performance.sh

sudo mount -t hugetlbfs hugetlbfs /dev/hugepages
sudo sysctl vm.nr_hugepages=6144

# Standard locations from the Ubuntu `ovmf` package; last one is arbitrary:
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp

sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
sudo chrt -r 1 taskset -c 4-15 qemu-system-x86_64 \
  -drive if=pflash,format=raw,readonly,file=$VGAPT_FIRMWARE_BIN \
  -drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  -enable-kvm \
  -machine q35,accel=kvm,mem-merge=off \
  -cpu host,kvm=off,topoext=on,host-cache-info=on,hv_relaxed,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_frequencies,hv_reset,hv_vendor_id=stevenwang,hv_spinlocks=0x1fff \
  -smp 12,sockets=1,cores=6,threads=2 \
  -m 12288 \
  -mem-prealloc \
  -mem-path /dev/hugepages \
  -vga none \
  -rtc base=localtime \
  -boot menu=off \
  -acpitable file=/home/coupe/kvm/SSDT1.dat \
  -device vfio-pci,host=01:00.0 \
  -device vfio-pci,host=01:00.1 \
  -device vfio-pci,host=01:00.2 \
  -device vfio-pci,host=01:00.3 \
  -drive file=/dev/nvme0n1p3,format=raw,if=virtio,cache=none,index=0 \
  -drive file=/dev/nvme0n1p4,format=raw,if=virtio,cache=none,index=1 \
  -drive file=/dev/nvme1n1p4,format=raw,if=virtio,cache=none,index=2 \
  -usb -device usb-host,hostbus=3,hostaddr=2 \
  -usb -device usb-host,hostbus=5,hostaddr=2 \
;

sudo bash /home/coupe/kvm/set_cpu_ondemand.sh
sudo bash /home/coupe/kvm/undo_bind_vfio.sh

# taskset 0xFFF0 qemu-system-x86_64 \
# -m 16384 -mem-prealloc -mem-path /dev/hugepages \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/TU106.rom \
# -drive file=/dev/sda,format=raw,if=virtio,cache=none,index=1 \
# -drive file=/home/coupe/D/vm/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
# -drive file=/home/coupe/D/vm/Win10_20H2_English_x64.iso,media=cdrom \
# -drive file=/home/coupe/D/vm/virtio-win-0.1.185.iso,media=cdrom \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/navi_10.rom \
# -net nic,model=virtio \

# hv_vendor_id is used for Nvidia Error 43 prevention
