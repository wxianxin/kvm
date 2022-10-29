# CPU pinning for QEMU vm

# set -x

########################################################################################
# systemd-cgls  # To display the whole cgroups hierarchy on your system

# TODO create systemd unit for vm and then pin the thread

# # pin all other system threads
# sudo systemctl set-property --runtime -- user.slice AllowedCPUs=16-19
# sudo systemctl set-property --runtime -- system.slice AllowedCPUs=16-19
# sudo systemctl set-property --runtime -- init.scope AllowedCPUs=16-19

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
        sudo taskset -cp $vcpu $pid;
        continue;
    fi

    if [[ $description == *"io0"* ]]
    then
        echo $description;
        sudo taskset -cp 12-15 $pid;
        continue;
    fi

    echo $description;
    sudo taskset -cp 12-15 $pid;

    echo;
done

