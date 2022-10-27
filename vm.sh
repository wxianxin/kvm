#!/bin/bash 

# Very useful guide for using qemu: https://archive.fosdem.org/2018/schedule/event/vai_qemu_jungle/
# how to use help:
#   qemu-system-x86_64 -device help
#   qemu-system-x86_64 -device pcie-root-port,help

set -x

########################################################################################
# qemu-img create -f qcow2 ~/D/vm/win11.qcow2 64G
# qemu-img create -f qcow2 -b ~/D/vm/win10.qcow2 win10_snapshot.img

########################################################################################
# toggles
network_bridge="no"
rebind_GPU="yes"
amd_cpu_performance="no"

########################################################################################
# network bridge
# a bridge is like a virtual switch
# a tap device is like a virtual nic
# virtio driver can leverage tap as nic for guest
if [ "$network_bridge" == "yes" ]; then
    echo "network_bridge: $network_bridge"
    sudo ip link add br0 type bridge
    sudo ip link set dev br0 up
    sudo ip link set dev enp3s0 master br0
    sudo ip link set enp3s0 up
    sudo ip tuntap add mode tap tap0
    sudo ip link set tap0 master br0
    sudo ip link set tap0 up
    sudo dhclient br0
fi

########################################################################################
# rebind GPU
if [ "$rebind_GPU" == "yes" ]; then
    echo "rebind_GPU: $rebind_GPU"
    sudo bash /home/coupe/kvm/bind_vfio.sh
fi

########################################################################################
# set AMD CPU to performance mode
if [ "$amd_cpu_performance" == "yes" ]; then
    echo "amd_cpu_performance: $amd_cpu_performance"
    sudo bash /home/coupe/kvm/set_cpu_performance.sh
fi

########################################################################################

sudo mount -t hugetlbfs hugetlbfs /dev/hugepages
sudo sysctl vm.nr_hugepages=8200 # 2M a piece

########################################################################################
# # Standard locations from the Ubuntu `ovmf` package
# export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
# export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
# Standard locations from the Archlinux `ovmf` package
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/x64/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/x64/OVMF_VARS.fd
# This location path is arbitrary
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp
########################################################################################

sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
# sudo chrt -r 1 taskset -c 4-15 /home/coupe/qemu-6.1.0/build/qemu-system-x86_64 \
sudo chrt -r 1 taskset -c 0-11 qemu-system-x86_64 \
  --name stevenqemu,debug-threads=on \
  --drive if=pflash,format=raw,readonly=on,file=$VGAPT_FIRMWARE_BIN \
  --drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  --enable-kvm \
  --machine q35,accel=kvm,mem-merge=off \
  --cpu host,kvm=off,topoext=on,host-cache-info=on,hv_relaxed,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_frequencies,hv_reset,hv_vendor_id=eeag,hv_spinlocks=0x1fff \
  --smp 12,sockets=1,cores=6,threads=2 \
  --m 16384 \
  --mem-prealloc \
  --mem-path /dev/hugepages \
  --vga none \
  --rtc base=localtime \
  --boot menu=on \
  --object iothread,id=io0 \
  --blockdev file,node-name=f0,filename=/home/coupe/vm/win11.qcow2 \
  --blockdev qcow2,node-name=q0,file=f0 \
  --device virtio-blk-pci,drive=q0,iothread=io0 \
  --blockdev host_device,node-name=q1,filename=/dev/nvme0n1p5 \
  --blockdev host_device,node-name=q2,filename=/dev/nvme0n1p6 \
  --device virtio-blk-pci,drive=q1,iothread=io0 \
  --device virtio-blk-pci,drive=q2,iothread=io0 \
  --drive file=/home/coupe/vm/Win11_22H2_English_x64v1.iso,media=cdrom \
  --drive file=/home/coupe/vm/virtio-win-0.1.225.iso,media=cdrom \
  --device pcie-root-port,id=abcd,chassis=1 \
  --device vfio-pci,host=03:00.0,bus=abcd,addr=00.0,multifunction=on \
  --device vfio-pci,host=03:00.1,bus=abcd,addr=00.1 \
  --device qemu-xhci,id=xhci \
  --device usb-host,bus=xhci.0,vendorid=0x046d,productid=0xc547,port=1 \
  --device usb-host,bus=xhci.0,vendorid=0x046d,productid=0xc548,port=2 \
  --device usb-host,bus=xhci.0,vendorid=0x8087,productid=0x0aaa,port=3 \
  --audiodev pa,id=ad0,out.mixing-engine=off,server=unix:/run/user/1000/pulse/native \
  --device ich9-intel-hda \
  --device hda-duplex,audiodev=ad0 \
;

########################################################################################
# undo rebind GPU
if [ "$rebind_GPU" == "yes" ]; then
    echo "rebind_GPU: $rebind_GPU"
    sudo bash /home/coupe/kvm/bind_vfio_undo.sh
fi

########################################################################################
# set AMD CPU back to ondemand mode
if [ "$amd_cpu_performance" == "yes" ]; then
    echo "amd_cpu_performance: $amd_cpu_performance"
    sudo bash /home/coupe/kvm/set_cpu_ondemand.sh
fi
########################################################################################

# taskset 0xFFF0 qemu-system-x86_64 \
# -m 16384 -mem-prealloc -mem-path /dev/hugepages \
# --vga none \
# --vga std \
# --device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/TU106.rom \
# --drive if=none,id=disk0,cache=none,aio=threads,format=qcow2,file=/home/coupe/vm/win11.qcow2 \
# --drive if=none,id=disk1,cache=none,aio=threads,format=raw,file=/dev/nvme0n1p5 \
# --drive file=/home/coupe/D/vm/Win11_English_x64v1.iso,media=cdrom \
# --drive file=/home/coupe/D/vm/virtio-win-0.1.215.iso,media=cdrom \
# --acpitable file=/home/coupe/kvm/SSDT1.dat \
# --usb -device usb-host,hostbus=1,hostaddr=7 \ # legacy USB passthrough(usb1.1/2.0)
# --device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=tap0,script=no,downscript=no \
#### Creative USB Audio
# --device usb-host,bus=xhci.0,vendorid=0x041e,productid=0x3274,port=2 \


########################################################################################
# hv_vendor_id is used for Nvidia Error 43 prevention
# chrt: -r robin round scheduler
# USB: ehci(usb2.0) xchi(usb3.0) controller
# About audio device (also QEMU USB emulator): such implementation requires very tight timing on the clock, so the performance is usually not satisfactory at first and it needs extensive tweaking.
