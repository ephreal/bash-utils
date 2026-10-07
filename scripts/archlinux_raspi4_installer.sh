#!/bin/bash
# Leave just ONE of these uncommented to choose your raspi archlinux version
# Note: armv7h doesn't work wiith raspi4 on the latest version of linux.
# No bueno.
# ARCH_VER="ArchLinuxARM-rpi-armv7-latest.tar.gz"

# Archlinux for Raspi 4+ and Raspi 5
ARCH_VER="ArchLinuxARM-rpi-aarch64-latest.tar.gz"

download_packages() {
    needed=()
    required_packages=("dosfstools" "sudo" "wget")

    for package in "${required_packages[@]}"; do
        if ! pacman -Qi "${package}" &>/dev/null; then 
            needed+=("$package")
        fi
    done

    if [ "${#needed[@]}" -gt 0 ]; then
        echo "Required packages are missing. Installing..."
        sudo pacman -Syu "${needed[@]}"
    fi
}

get_devices() {
    # Ensure the array is passed in
    [[ -n $1 ]] || {
        echo "Array for devices must be passed to get_devices"
        exit 1
    }
    [[ -n $2 ]] || {
        echo "Device type must be passed to get_devices"
        exit 1
    }
    # Requires you to pass in an array that is filled out in
    # this function. Since the array is updated by reference,
    # the values are available to the caller after.
    local -n devs=$1
    local -n dev_type=$2
    local selection

    while true; do
        echo "Which type of device are you looking for?"
        echo "1) SD Card (/dev/mmcblkX)"
        echo "2) Block (/dev/sdX)"
        read -r selection

        case "${selection}" in
            1)
                shopt -s nullglob 
                devs=( /dev/mmcblk[0-9] )
                shopt -u nullglob
                dev_type="sd-card"
                break
                ;;
            2)
                shopt -s nullglob
                devs=( /dev/sd[a-z] )
                shopt -u nullglob
                dev_type="block"
                break
                ;;
            *)
                echo ""
                echo "Invalid Selection"
                echo ""
                ;;
        esac
    done

    # Check if any devices were found.
    # If not, there is no sense continuing.
    if ((${#devs[@]} == 0)); then
        echo "No devices found" >&2
        exit 1
    fi
    return 0
}

select_device() {
    [[ -n $1 ]] || {
        echo "Variable for selected device must be passed to select_device"
        exit 1
    }
    [[ -n $2 ]] || {
        echo "Devices array must be passed into select_device"
        exit 1
    }

    local -n selection=$1
    local -n devices=$2
    local choice
    local counter=1

    # Check whether or not we need to have the user make a selection
    if [ ${#devices[@]} -eq 1 ]; then
        echo "Only one device found."
        selection="${devices[0]}"
        return 0
    fi

    echo "Which device do you want to use?"
    for dev in "${devices[@]}"; do
        echo "${counter}) ${dev}"
        ((counter++))
    done

    read -r choice
    [[ $choice =~ ^[0-9]+$ ]] || choice=0

    while [[ $choice -le 0 || $choice -gt ${#devices[@]} ]]; do
        echo "Invalid selection. Please try again"
        read -r choice
        [[ $choice =~ ^[0-9]+$ ]] || choice=0
    done
    selection="${devices[choice-1]}"
    return 0
}

format_device() {
    [[ -n $1 ]] || {
        echo "Variable for selected device must be passed to format_sd"
        exit 1
    }

    local device=$1

    echo "Format commencing in 3 seconds. Ctrl+C to cancel."
    sleep 1
    echo "Format commencing in 2 seconds."
    sleep 1
    echo "Format commencing in 1 second."
    sleep 1
    echo "Format commencing."

    sudo umount $device?*
    # This part looks a little weird because fdisk accepts input directly from the stdin
    # The regex simply lets this strip out the comments while still running the command
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk $device
        o # New Partition Table
        n # New partition
        p # Primary Partition 
        1 # Partition number 1
          # Confirm default start position (newline)
        +1024M # Make partition 1Gb in size
        t # Set the partition type
        c # Choose the partition type W95 FAT32
        n # New partition
        p # Primary partition type
        2 # Partition number 2
          # send newlines twice to make the partition as big as the entire remaining space
          # Newline 2
        w # Write the changes
EOF

    # Slight pause to allow the partition tables to update before we start making directories
    sudo partprobe "${device}"; sleep 1
}

get_boot_and_root_partition() {
    [[ -n $1 ]] || {
        echo "Block device must be passed to get_boot_and_root_partition"
        exit 1
    }

    [[ -n $2 ]] || {
        echo "Variable to store the boot partition in must be passed to get_boot_and_root_partition"
        exit 1
    }

    [[ -n $3 ]] || {
        echo "Variable to store the root partition in must be passed to get_boot_and_root_partition"
        exit 1
    }

    [[ -n $4 ]] || {
        echo "Type of block device must be passed into get_boot_and_root_partition"
        exit 1
    }

    local device=$1
    local -n boot=$2
    local -n root=$3
    local dev_selection=$4

    # Get boot partition
    if [[ $dev_selection == "sd-card" ]]; then
        boot="${device}p1"
        root="${device}p2"
    else
        boot="${device}1"
        root="${device}2"
    fi
}

format_partitions() {
    [[ -n $1 ]] || {
        echo "Boot partition must be passed to format_partitions"
        exit 1
    }

    [[ -n $2 ]] || {
        echo "Root partition must be passed to format_partitions"
        exit 1
    }

    local boot=$1
    local root=$2

    # Ensure boot and root are unmounted. Some desktop environments automatically mount partitions.
    sudo umount $boot
    sudo umount $root

    # Format root and boot partitions.
    echo "Writing VFAT to ${boot}"
    sudo mkfs.vfat $boot
    mkdir boot
    sudo mount $boot boot

    echo "Writing ext4 to to ${root}"
    sudo mkfs.ext4 $root
    mkdir root
    sudo mount $root root

}

install_archlinux() {
    [[ -n $1 ]] || {
        echo "hostname must be passed to install_archlinux"
        exit 1
    }

    local hname=$1

    if [ ! -f $ARCH_VER ]; then
        wget http://os.archlinuxarm.org/os/$ARCH_VER
    fi

    # Extract the arch iso into the local root directory
    sudo bsdtar -xpf $ARCH_VER -C "root"
    sudo sync

    # sudo echo "${hname}" > root/etc/hostname
    # Echo the value to a process running as root since this requires root permissions
    echo "${hname}" | sudo tee root/etc/hostname >/dev/null

    sudo mv -f root/boot/* boot/


    # Note: This *MAY* need to happen on block devices as well, but I've
    # never had the opportunity to test that.
    # I'm only targeting the SD cards until I know it has to happen.
    if [ $ARCH_VER == "ArchLinuxARM-rpi-aarch64-latest.tar.gz" ]; then
        sudo sed -i 's/mmcblk0/mmcblk1/g' 'root/etc/fstab'
    fi
}

cleanup() {
    [[ -n $1 ]] || {
        echo "Boot partition must be passed to cleanup"
        exit 1
    }

    [[ -n $2 ]] || {
        echo "Root partition must be passed to cleanup"
        exit 1
    }

    local boot=$1
    local root=$2

    sudo umount boot root

    echo "The SD card should now be ready to use. Insert it into the raspberry pi and log in."
    echo "The default username and password are"
    echo "Username: alarm"
    echo "Password: alarm"
    echo
    echo "root pass: root"
    echo
    echo "Once you have logged in, be sure to init/populate the archlinux keyring"
    echo "pacman-key --init && pacman-key --populate archlinuxarm"


    sudo rm -rf boot
    sudo rm -rf root

}

DEVICES=()
DEVICE_TYPE=""
SELECTED_DEVICE=""
BOOT_PARTITION=""
ROOT_PARTITION=""

download_packages
get_devices DEVICES DEVICE_TYPE
select_device SELECTED_DEVICE DEVICES

echo "Using ${SELECTED_DEVICE}"
echo "Is this correct? y/n"
read -r confirmation

if [ "$confirmation" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

while [[ -z $NEW_HOSTNAME ]]; do
    echo "What is the hostname of this device?"
    read -r NEW_HOSTNAME
done

format_device $SELECTED_DEVICE
get_boot_and_root_partition $SELECTED_DEVICE BOOT_PARTITION ROOT_PARTITION $DEVICE_TYPE

format_partitions $BOOT_PARTITION $ROOT_PARTITION
install_archlinux "${NEW_HOSTNAME}"
cleanup $BOOT_PARTITION $ROOT_PARTITION
exit 0
