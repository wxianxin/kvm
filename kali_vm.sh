########################################################################################
sudo mount /dev/nvme0n1p9 D

sudo mount -t hugetlbfs hugetlbfs /dev/hugepages
sudo sysctl vm.nr_hugepages=8200 # 2M a piece
########################################################################################
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/x64/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/x64/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp
########################################################################################
sudo cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
sudo systemd-run --slice=kali_qemu.slice  --unit=steven_qemu --property="AllowedCPUs=0-15" qemu-system-x86_64 \
  --name stevenqemu,debug-threads=on \
  --pidfile /run/steven_qemu.pid \
  `# --drive if=pflash,format=raw,readonly=on,file=$VGAPT_FIRMWARE_BIN` \
  `# --drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP` \
  --enable-kvm \
  --machine q35,accel=kvm,mem-merge=off \
  --cpu host,kvm=off,topoext=on,host-cache-info=on,hv_relaxed,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_frequencies,hv_reset,hv_vendor_id=eeag,hv_spinlocks=0x1fff \
  --smp 12,sockets=1,cores=6,threads=2 \
  --m 16384 \
  --mem-prealloc \
  --mem-path /dev/hugepages \
  --nodefaults \
  --nographic \
  --vga std \
  --vnc :0 \
  --rtc base=localtime \
  --boot menu=on \
  --object iothread,id=io0 \
  --blockdev file,node-name=f0,filename=/home/coupe/D/vm/kali-linux-2023.1-qemu-amd64.qcow2 \
  --blockdev qcow2,node-name=q0,file=f0 \
  --device virtio-blk-pci,drive=q0,iothread=io0 \
  --blockdev file,node-name=f1,filename=/home/coupe/L/drive.qcow2 \
  --blockdev qcow2,node-name=q1,file=f1 \
  --device virtio-blk-pci,drive=q1,iothread=io0 \
  --audiodev pa,id=ad0,out.mixing-engine=off,server=unix:/run/user/1000/pulse/native \
  --device ich9-intel-hda \
  --device hda-duplex,audiodev=ad0 \
  --netdev user,id=u1 -device e1000,netdev=u1 \
;

