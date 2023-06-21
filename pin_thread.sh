# CPU pinning for QEMU vm

# set -x

########################################################################################
# systemd-cgls  # To display the whole cgroups hierarchy on your system
# systemctl list-units --type=service --state=running
# systemctl status --full
# systemctl status --full myservice.service
# journalctl -b -u myservice.service
########################################
# clean up failed units and free up the service name spaces.
# sudo systemctl --failed
# sudo systemctl reset-failed
# Good reading on how to configure systemd unit: https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files
########################################
# check logs for a service
# journalctl -u steven_qemu.service
# delete logs
# journalctl --flush --unit=steven_qemu.service
########################################

# ping all other system threads
sudo systemctl set-property --runtime -- user.slice AllowedCPUs=14-15
sudo systemctl set-property --runtime -- system.slice AllowedCPUs=14-15
sudo systemctl set-property --runtime -- init.scope AllowedCPUs=14-15

########################################################################################
# In qemu command window, get vcpu process id by executing `info cpus`

qemu_pid=$(sudo cat /run/steven_qemu.pid)
# ls -1 /proc/$qemu_pid/task   # see all child process

for child in /proc/$qemu_pid/task/*;
do
    pid=$(basename $child);
    description=$(cat $child/comm);    # get the description name (for logic) 

    if [ $qemu_pid == $pid ]
    then
        continue
    fi

    if [[ $description == "CPU"* ]]
    then
        echo $description;
        vcpu=$(echo $description | tr -dc '0-9');
        # sudo taskset -cp $vcpu $pid;
        sudo taskset -cp $((($vcpu / 2) + 8 * ($vcpu % 2))) $pid;
        continue;
    fi

    if [[ $description == *"io0"* ]]
    then
        echo $description;
        sudo taskset -cp 6,14 $pid;
        continue;
    fi

    echo $description;
    sudo taskset -cp 6,14 $pid;

    echo;
done

