# qemu-img create -f qcow2 ~/D/vm/kvm_win10.qcow2 48G

# Standard locations from the Ubuntu `ovmf` package; last one is arbitrary:
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp

sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
sudo chrt -r 1 taskset -c 4-7 qemu-system-x86_64 \
  -drive if=pflash,format=raw,readonly,file=$VGAPT_FIRMWARE_BIN \
  -drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  -enable-kvm \
  -machine q35,accel=kvm,mem-merge=off \
  -cpu host,kvm=off,topoext=on,host-cache-info=on,hv_relaxed,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_frequencies,hv_reset,hv_vendor_id=stevenwang,hv_spinlocks=0x1fff \
  -smp 4,sockets=1,cores=2,threads=2 \
  -m 8192 \
  -vga std \
  -boot menu=on \
  -rtc base=localtime \
  -drive file=/home/coupe/kvm_win10.qcow2,format=qcow2,if=virtio,cache=none,index=0 \
;


# taskset 0xFFF0 qemu-system-x86_64 \
# -m 16384 -mem-prealloc -mem-path /dev/hugepages \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/TU106.rom \
# -drive file=/dev/sda,format=raw,if=virtio,cache=none,index=1 \
# -drive file=/home/coupe/Downloads/Win10_20H2_v2_English_x64.iso,media=cdrom \
# -drive file=/home/coupe/Downloads/virtio-win-0.1.185.iso,media=cdrom \
# -device vfio-pci,host=01:00.0,romfile=/home/coupe/D/vm/navi_10.rom \
# -net nic,model=virtio \

########################################################################################
# hv_vendor_id is used for Nvidia Error 43 prevention
# !!! If created vm is using virtio, DO NOT qemu-system-x86_64 start without drive option "if=virtio", you will get BSOD
