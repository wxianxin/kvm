#!/bin/bash 

set -x
########################################################################################
# to run as systemd unit service(Use root account, as sudo command may timeout after long sessions):
# systemd-run --slice=steven_qemu.slice  --unit=steven_qemu --property="AllowedCPUs=0-15" /bin/bash /path/to/vm.sh
########################################################################################
# Very useful guide for using qemu: https://archive.fosdem.org/2018/schedule/event/vai_qemu_jungle/
# how to use help:
#   qemu-system-x86_64 -device help
#   qemu-system-x86_64 -device pcie-root-port,help

########################################################################################
# storage IO

# iscsi dependency
# pacman -S qemu-block-iscsi

# qemu-img create -f qcow2 ~/vm/w10.qcow2 64G
# qemu-img create -f qcow2 -o backing_file=/path/to/base/image.qcow2,backing_fmt=qcow2 /path/to/snapshot/image.qcow2
# qemu-system-x86_64 -drive file=/path/to/snapshot/image.qcow2,if=virtio

# remove qcow2 sparse space and compression
## Noop conversion (qcow2-to-qcow2) removes sparse space:
# qemu-img convert -O qcow2 source.qcow2 shrunk.qcow2
## You can also try add compression (-c) to the output image:
# qemu-img convert -c -O qcow2 source.qcow2 shrunk.qcow2

# mount qcow2 on host
# sudo modprobe nbd max_part=8
# sudo qemu-nbd --connect=/dev/nbd0 /home/$LOGNAME/vm/share.qcow2
# sudo mount -t ntfs3 /dev/nbd0p2 bkp
# # undo
# sudo qemu-nbd --disconnect /dev/nbd0

########################################################################################
# toggles
pin_cpu="yes"
rebind_GPU="yes"
network_bridge="no"
set_cpu_performance="yes"

########################################################################################
# Source VFIO functions
source /home/$LOGNAME/kvm/scripts/bind_vfio.sh
source /home/$LOGNAME/kvm/scripts/set_cpu_performance.sh

########################################################################################
# network bridge
# a bridge is like a virtual switch
# a tap device is like a virtual nic
# virtio driver can leverage tap as nic for guest
# NOTE: dhclient is requried.
if [ "$network_bridge" == "yes" ]; then
    echo "network_bridge: $network_bridge"
    sudo ip link add br0 type bridge
    sudo ip link set dev br0 up
    sudo ip link set dev enp0s31f6 master br0
    sudo ip link set enp3s0 up
    sudo ip tuntap add mode tap tap0
    sudo ip link set tap0 master br0
    sudo ip link set tap0 up
    sudo dhclient br0
fi
########################################################################################
# mount the storage. NOTE: this has to be after the network bridge setup.
# sudo mount /dev/nvme0n1p2 /home/$LOGNAME/vm
# bash /home/$LOGNAME/config/fc.sh
sudo mount -o rsize=32768,wsize=32768 192.168.8.99:/mnt/vault/clustervault ~/nfs
# sudo mount -t cifs -o username=guest,uid=coupe,vers=2.0 "//192.168.8.1/Seagate_BUP_BK(08E5)"  ~/bkp
########################################################################################
# rebind GPU
if [ "$rebind_GPU" == "yes" ]; then
    if lspci -knn | grep -q vfio; then
        echo "GPU already binded to VFIO !!!"
    else
        echo "rebind_GPU: $rebind_GPU"
        bind_vfio
        sleep 3
    fi

fi
########################################################################################
# set CPU performance
if [ "$set_cpu_performance" == "yes" ]; then
    echo "set_cpu_performance: $set_cpu_performance"
    set_cpu_lp
fi

########################################################################################
echo 1 | sudo tee /proc/sys/vm/compact_memory   # defragment RAM
sudo mount -t hugetlbfs nodev /dev/hugepages
sudo sysctl vm.nr_hugepages=8200 # 2M a piece
########################################################################################
# UEFI (OVMF)
# export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
# export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
# Standard locations from the Archlinux `ovmf` package
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/x64/OVMF_CODE.4m.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/x64/OVMF_VARS.4m.fd
# This location path is arbitrary
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.4m.fd.tmp
########################################################################################
# looking glass
bash /home/$LOGNAME/kvm/looking_glass.sh
########################################################################################

sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
# sudo taskset 0xFFF0 qemu-system-x86_64 \
# sudo chrt -r 1 taskset -c 4-15 /home/$LOGNAME/qemu-6.1.0/build/qemu-system-x86_64 \
# sudo chrt -r 1 taskset -c 0-11 qemu-system-x86_64 \
# here for CPU core count, use desired core count + IO + worker thread. eg. 6*2(guest) + 2(IO) + 2(worker) = 16
sudo systemd-run --slice=steven_qemu.slice  --unit=steven_qemu --property="AllowedCPUs=0-9,16-25" \
  `#--setenv=XDG_RUNTIME_DIR=/run/user/1000 `\
  --setenv=PIPEWIRE_RUNTIME_DIR=/run/user/1000 \
  `#--setenv=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus `\
  qemu-system-x86_64 \
  --name steven_qemu,debug-threads=on \
  --pidfile /run/steven_qemu.pid \
  --drive if=pflash,format=raw,readonly=on,file=$VGAPT_FIRMWARE_BIN \
  --drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  --enable-kvm \
  --machine q35,accel=kvm,mem-merge=off \
  --cpu host,migratable=off,kvm=off,host-cache-info=on,-aes,-x2apic,+hypervisor,+topoext,+pdpe1gb,+tsc-deadline,+tsc_adjust,+arch-capabilities,+rdctl-no,+skip-l1dfl-vmentry,+mds-no,+pschange-mc-no,+invtsc,+xsaves,+perfctr_core,+clzero,+xsaveerptr,hv_relaxed,hv_vapic,hv_spinlocks=8191,hv_vpindex,hv_synic,hv_time,hv_stimer,hv_stimer_direct,hv_reset,hv_vendor_id=AuthenticAMD,hv_frequencies,hv_tlbflush,hv_ipi,hv_avic,-hv-reenlightenment,-hv-evmcs \
  `# tested benign flags --cpu +amd-stibp,+ibpb,+stibp,+virt-ssbd,+amd-ssbd,+cmp_legacy,`\
  --smbios type=0,vendor="AMI",version="F21",date="10/01/2024" \
  --smbios type=1,manufacturer="Asus",product="STRIX",version="1.0",serial="12345678",uuid="40047947-413f-4188-93bc-c6a6e0747e9a",sku="B650EI",family="B650E MB" \
  --smp 16,sockets=1,cores=8,threads=2 \
  --object memory-backend-file,id=mem0,size=16G,mem-path=/dev/hugepages,prealloc=on,share=on \
  --machine memory-backend=mem0 \
  --m 16G \
  --nodefaults \
  --nographic \
  `#--vga virtio` \
  `#--vnc :0` \
  --rtc base=localtime,clock=host,driftfix=slew \
  --boot menu=on \
  --drive file=/home/$LOGNAME/nfs/vm/en-us_windows_11_iot_enterprise_ltsc_2024_x64_dvd_f6b14814.iso,media=cdrom \
  --drive file=/home/$LOGNAME/nfs/vm/virtio-win-0.1.271.iso,media=cdrom \
  --object iothread,id=io0 \
  --blockdev file,node-name=f0,filename=/home/$LOGNAME/vm/w11i.qcow2 \
  --blockdev qcow2,node-name=q0,file=f0 \
  --device virtio-blk-pci,drive=q0,iothread=io0 \
  --blockdev host_device,node-name=q1,filename=/dev/nvme0n1p4 \
  --device virtio-blk-pci,drive=q1,iothread=io0 \
  --blockdev file,node-name=f1,filename=/home/$LOGNAME/vm/share.qcow2 \
  --blockdev qcow2,node-name=q2,file=f1 \
  --device virtio-blk-pci,drive=q2,iothread=io0 \
  --device pcie-root-port,id=abcd,chassis=1 \
  --device vfio-pci,host=03:00.0,bus=abcd,addr=00.0,multifunction=on \
  --device vfio-pci,host=03:00.1,bus=abcd,addr=00.1 \
  --device vfio-pci,host=03:00.2,bus=abcd,addr=00.2 \
  --device vfio-pci,host=03:00.3,bus=abcd,addr=00.3 \
  --audiodev pipewire,id=ad0 --device ich9-intel-hda --device hda-duplex,audiodev=ad0 \
  --netdev user,id=usernet -device e1000,netdev=usernet \
  `#--device virtio-net,netdev=net0 -netdev tap,id=net0,ifname=tap0,script=no,downscript=no` \
  --device ivshmem-plain,id=shmem0,memdev=looking-glass \
  --object memory-backend-file,id=looking-glass,mem-path=/dev/kvmfr0,size=256M,share=yes \
  --spice port=5900,addr=127.0.0.1,disable-ticketing \
  --device virtio-keyboard-pci \
  --device virtio-mouse-pci \
  --device qemu-xhci,id=xhci \
  `#--device usb-host,bus=xhci.0,vendorid=0x3151,productid=0x4011,port=1` \
  `#--device usb-host,bus=xhci.0,vendorid=0x373b,productid=0x101a,port=2` \
  `#--device usb-host,bus=xhci.0,vendorid=0x1462,productid=0x3fa4,port=3` \
;

  # --blockdev file,node-name=f1,filename=iscsi://%@192.168.50.40:3260/iqn.2022-11.stevenwang.trade:drive/0 \
  #
#   --iscsi initiator-name=iqn.2022-11.stevenwang.trade:node01.initiator01 \
#   --iscsi header-digest=CRC32C \
#   --drive file=iscsi://%@192.168.50.40:3260/iqn.2022-11.stevenwang.trade:drive/0,format=raw,if=none,id=iscsidrive,cache=none \

########################################################################################
if [ "$pin_cpu" == "yes" ]; then
    sleep 3
    bash /home/$LOGNAME/kvm/pin_thread.sh
fi
########################################################################################

# --vga none \
# --device vfio-pci,host=01:00.0,romfile=/home/$LOGNAME/D/vm/TU106.rom \
# --drive if=none,id=disk0,cache=none,aio=threads,format=qcow2,file=/home/$LOGNAME/vm/win11.qcow2 \
# --drive if=none,id=disk1,cache=none,aio=threads,format=raw,file=/dev/nvme0n1p5 \
# --acpitable file=/home/$LOGNAME/kvm/SSDT1.dat \
# --usb -device usb-host,hostbus=1,hostaddr=7 \ # legacy USB passthrough(usb1.1/2.0)

########################################################################################
# Notes:
# hv_vendor_id is used for Nvidia Error 43 prevention
# chrt: -r robin round scheduler
# USB: ehci(usb2.0) xchi(usb3.0) controller
# About audio device (also QEMU USB emulator): such implementation requires very tight timing on the clock, so the performance is usually not satisfactory at first and it needs extensive tweaking.
# Error about init pa when sudo qemu: fix: sudo cp /home/$LOGNAME/.config/pulse/cookie /root/.config/pulse/cookie
