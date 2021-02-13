# qemu-img create -f qcow2 ~/D/vm/win10.qcow2 48G
# qemu-img create -f qcow2 -b ~/D/vm/win10.qcow2 win10_snapshot.img

# unbind driver after boot process
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/devices/0000:01:00.2/driver/unbind'
# sudo sh -c 'echo "0000:01:00.2" > /sys/bus/pci/drivers/vfio-pci/bind'

########################################################################################
# network bridge
# a bridge is like a virtual switch
# a tap device is like a virtual nic
# virtio driver can leverage tap as nic for guest
sudo ip link add br0 type bridge
sudo ip link set dev br0 up
sudo ip link set dev enp4s0 master br0
sudo ip link set enp4s0 up
sudo ip tuntap add mode tap tap0
sudo ip link set tap0 master br0
sudo ip link set tap0 up
sudo dhclient br0
########################################################################################


sudo bash /home/coupe/kvm/bind_vfio.sh
# sudo bash /home/coupe/kvm/set_cpu_performance.sh

sudo mount -t hugetlbfs hugetlbfs /dev/hugepages
sudo sysctl vm.nr_hugepages=5200

# Standard locations from the Ubuntu `ovmf` package; last one is arbitrary:
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp

sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
sudo chrt -r 1 taskset -c 2-7 qemu-system-x86_64 \
  -D ./qemu.log \
  -drive if=pflash,format=raw,readonly,file=$VGAPT_FIRMWARE_BIN \
  -drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  -enable-kvm \
  -machine q35,accel=kvm,mem-merge=off \
  -cpu host,kvm=off,topoext=on,host-cache-info=on,hv_relaxed,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_frequencies,hv_reset,hv_vendor_id=stevenwang,hv_spinlocks=0x1fff \
  -smp 6,sockets=1,cores=3,threads=2 \
  -m 10240 \
  -mem-prealloc \
  -mem-path /dev/hugepages \
  -vga none \
  -rtc base=localtime \
  -boot menu=on \
  -drive file=/home/coupe/D/vm/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
  -drive file=/dev/nvme0n1p6,format=raw,if=virtio,cache=none,index=2 \
  -drive file=/dev/nvme0n1p7,format=raw,if=virtio,cache=none,index=1 \
  -device vfio-pci,host=02:00.0 \
  -device vfio-pci,host=02:00.1 \
  -device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=tap0,script=no,downscript=no \
  -usb -device usb-host,hostbus=1,hostaddr=6 \
  -usb -device usb-host,hostbus=1,hostaddr=7 \
  -usb -device usb-host,hostbus=1,hostaddr=10 \
;


# sudo bash /home/coupe/kvm/set_cpu_ondemand.sh
# sudo bash /home/coupe/kvm/undo_bind_vfio.sh

# taskset 0xFFF0 qemu-system-x86_64 \
# -m 16384 -mem-prealloc -mem-path /dev/hugepages \
# -vga none \
# -vga std \
# -soundhw hda
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/TU106.rom \
# -drive file=/dev/sda,format=raw,if=virtio,cache=none,index=1 \
# -drive file=/home/coupe/D/vm/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
# -drive file=/home/coupe/D/vm/Win10_20H2_English_x64.iso,media=cdrom \
# -drive file=/home/coupe/D/vm/virtio-win-0.1.185.iso,media=cdrom \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/navi_10.rom \
# -acpitable file=/home/coupe/kvm/SSDT1.dat \
# -net nic -net bridge,br=br0 \

########################################################################################
# hv_vendor_id is used for Nvidia Error 43 prevention
# !!! If vm created using virtio, DO NOT qemu-system-x86_64 start without drive option "if=virtio", otherwise BSOD
