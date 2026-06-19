# VM Image Storage Plan

This note is for running Windows game storage as a file-backed QEMU disk without the corruption/I/O errors seen from the current setup.

## What Happened

The VM image files are stored under `/home/s/vm`, which is on Btrfs with compression enabled. The image files were not marked NOCOW, and QEMU was using direct I/O:

```bash
aio=io_uring,cache.direct=on,cache.no-flush=off
```

During a VM run, the host kernel reported Btrfs checksum failures and direct I/O failures, including against `/home/s/vm/d.raw`. When Windows or PUBG reports file corruption from that disk, it is likely seeing real host-side read failures, not just a game or Steam issue.

Dedicated host partitions appeared more reliable because they avoid the extra filesystem/image-file layer.

## Recommended Layout

Use a dedicated Btrfs NOCOW directory for VM images, then create fresh images inside it.

Preferred options:

- Game disk: qcow2 if you want convenience and snapshots.
- Maximum performance/reliability game disk: raw file.
- OS disk: qcow2 is fine, especially if snapshots matter.

Do not reuse an image that already produced checksum or game corruption errors as your proof test. Create a fresh disk, format it inside Windows, and reinstall or verify the game.

## Create A Safe Qcow2 Game Disk

Stop the VM first.

```bash
mkdir -p ~/vm-nocow
sudo chattr +C ~/vm-nocow
lsattr -d ~/vm-nocow
```

The `lsattr` output should include `C` for the directory. That is the important part: new files created under this directory will inherit Btrfs NOCOW. Do not use `btrfs property set ... compression none`; `none` is not a valid value on this system.

Create the qcow2 image after the directory is marked NOCOW:

```bash
qemu-img create -f qcow2 \
  -o compat=1.1,lazy_refcounts=on,preallocation=metadata \
  ~/vm-nocow/games.qcow2 300G

qemu-img info ~/vm-nocow/games.qcow2
qemu-img check ~/vm-nocow/games.qcow2
```

Use this QEMU blockdev style:

```bash
--blockdev driver=file,node-name=f_games,filename=/home/$LOGNAME/vm-nocow/games.qcow2,aio=threads,cache.direct=off,cache.no-flush=off
--blockdev driver=qcow2,node-name=q_games,file=f_games,discard=unmap
--device virtio-blk-pci,drive=q_games,iothread=io2
```

## Raw Alternative

For the most boring and reliable game disk, use a fully preallocated raw file:

```bash
qemu-img create -f raw -o preallocation=full ~/vm-nocow/games.raw 300G
qemu-img info ~/vm-nocow/games.raw
```

Use this QEMU blockdev style:

```bash
--blockdev driver=file,node-name=f_games,filename=/home/$LOGNAME/vm-nocow/games.raw,aio=threads,cache.direct=off,cache.no-flush=off
--blockdev driver=raw,node-name=q_games,file=f_games,discard=unmap
--device virtio-blk-pci,drive=q_games,iothread=io2
```

## Host Health Checks

Run a scrub and check Btrfs device stats:

```bash
sudo btrfs scrub start -Bd /home
sudo btrfs device stats /home
```

Watch for new errors after using the new disk:

```bash
journalctl -k -b --grep 'BTRFS.*csum failed|direct IO failed'
```

Also check hardware stability if corruption counters keep increasing:

- NVMe/SSD SMART data.
- RAM stability.
- CPU/RAM undervolt or overclock settings.

Do not start with `btrfs check --repair`; that is a last-resort recovery action, not routine maintenance.

## Important Safety Notes

- Never mount a VM disk image on the host while the guest can write to it.
- Marking an existing directory NOCOW does not rewrite existing files. Create a new empty NOCOW directory, then create or copy-convert images into it.
- `chattr +C` must be applied before creating the image file.
- If converting old images, treat the result as suspect until Windows and game-level verification pass.
- Keep `cache.no-flush=off`; do not lie to the guest about flushes.
