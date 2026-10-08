#!/bin/bash
# Leave just ONE of these uncommented to choose your raspi archlinux version
# Note: armv7h doesn't work wiith raspi4 on the latest version of linux.
# No bueno.
# ARCH_VER="ArchLinuxARM-rpi-armv7-latest.tar.gz"

# Archlinux for Raspi 4+ and Raspi 5
ARCH_VER="ArchLinuxARM-rpi-aarch64-latest.tar.gz"
SETUP_SCRIPT=""
NOCONFIRM=false
REMOVE_ALARM=false
PUBKEY=""

DEVICES=()
DEVICE_TYPE=""
SELECTED_DEVICE=""
BOOT_PARTITION=""
ROOT_PARTITION=""

###############################################################################
# Input Handling and CLI Parsing
###############################################################################
usage() {
    echo ""
    echo "Usage: $0 [-s|--setup-script FILE] [-d|--device DEVICE] [-t|--device_type <block|sd-card>] [-s|--setup-script PATH] [-k|--public-key PATH] [--remove-alarm] [--no-confirm]" >&2

    echo "$0 arguments
    -h|--help                   Print this help text
    -d|--device       [DEVICE]  The device to install archlinuxarm on
    -t|--device-type  [sd-card | block] The device type specified by --device
    -s|--setup-script [FILE]    Script to run on first boot after installation
    -k|--public-key   [FILE]    SSH Key to install for root
    --remove-alarm              Remove the default alarm user from the install
    --no-confirm                Assume yes to any questions in this script
    "
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--setup-script) [[ -n $2 ]] || usage; SETUP_SCRIPT=$2; shift 2 ;;
        -d|--device)       [[ -n $2 ]] || usage; SELECTED_DEVICE=$2; shift 2 ;;
        -t|--device-type)  [[ -n $2 ]] || usage; DEVICE_TYPE=$2; shift 2 ;;
        -k|--public-key)   [[ -n $2 ]] || usage; PUBKEY=$2; shift 2 ;;
        -r|--remove-alarm) REMOVE_ALARM=true; shift ;;
        --no-confirm)      NOCONFIRM=true; shift ;;
        -h|--help)         usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

# Validate the flags needed for running the script
# Device given with -d but no type: partition naming needs it
if [[ -n $SELECTED_DEVICE && -z $DEVICE_TYPE ]]; then
    echo "A device type (-t sd-card|block) is required when using -d." >&2
    exit 1
fi

if [[ -n $DEVICE_TYPE && $DEVICE_TYPE != "sd-card" && $DEVICE_TYPE != "block" ]]; then
    echo "Invalid device type: ${DEVICE_TYPE} (use sd-card or block)" >&2
    exit 1
fi

# Alarm removed with no SSH key: warn, and pause unless --no-confirm
if $REMOVE_ALARM && [[ -z $PUBKEY ]]; then
    echo "WARNING: --remove-alarm without --public-key leaves no SSH login." >&2
    if ! $NOCONFIRM; then
        read -rp "Continue anyway? y/n " answer
        [[ $answer == "y" ]] || { echo "Exiting..."; exit 1; }
    fi
fi

###############################################################################
# Function Declarations
###############################################################################
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
        sudo pacman -Syu --noconfirm "${needed[@]}"
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
    sudo umount "${boot}"
    sudo umount "${root}"

    # Format root and boot partitions.
    echo "Writing VFAT to ${boot}"
    sudo mkfs.vfat "${boot}"
    mkdir boot
    sudo mount "${boot}" boot

    echo "Writing ext4 to to ${root}"
    if $NOCONFIRM; then
        sudo mkfs.ext4 -F "${root}"
    else
        sudo mkfs.ext4 "${root}"
    fi
    mkdir root
    sudo mount "${root}" root

}

install_archlinux() {
    if [ ! -f $ARCH_VER ]; then
        wget http://os.archlinuxarm.org/os/$ARCH_VER
    fi

    # Extract the arch iso into the local root directory
    sudo bsdtar -xpf $ARCH_VER -C "root"
    sudo sync

    sudo mv -f root/boot/* boot/

    # Note: This *MAY* need to happen on block devices as well, but I've
    # never had the opportunity to test that.
    # I'm only targeting the SD cards until I know it has to happen.
    if [ $ARCH_VER == "ArchLinuxARM-rpi-aarch64-latest.tar.gz" ]; then
        sudo sed -i 's/mmcblk0/mmcblk1/g' 'root/etc/fstab'
    fi
}

install_setup_script() {
    [[ -n $1 ]] || {
        echo "No setup script passed to install_setup_script"
        exit 1
    }

    local script=$1

    sudo install -D -m 0700 -o root -g root "${script}" "root/usr/local/sbin/firstboot-setup.sh"
    sudo chmod +x "root/usr/local/sbin/firstboot-setup.sh"

    sudo tee root/etc/systemd/system/firstboot-setup.service >/dev/null <<'EOF' || exit 1
[Unit]
Description=First-boot setup
Wants=network-online.target
After=network-online.target time-sync.target
ConditionPathExists=/usr/local/sbin/firstboot-setup.sh

[Service]
Type=oneshot
TimeoutStartSec=0
StandardOutput=append:/var/log/firstboot-setup.log
StandardError=inherit
ExecStartPre=/usr/bin/pacman-key --init
ExecStartPre=/usr/bin/pacman-key --populate archlinuxarm
ExecStart=/usr/local/sbin/firstboot-setup.sh
ExecStartPost=-/usr/bin/gpgconf --homedir /etc/pacman.d/gnupg --kill all
ExecStartPost=/usr/bin/rm -f /usr/local/sbin/firstboot-setup.sh
ExecStartPost=/usr/bin/systemctl disable firstboot-setup.service

[Install]
WantedBy=multi-user.target
EOF

    # Enable the unit by creating the symlink systemctl enable would make.
    # The target is absolute as seen from *inside* the image.
    sudo mkdir -p root/etc/systemd/system/multi-user.target.wants
    sudo ln -sf /etc/systemd/system/firstboot-setup.service \
        root/etc/systemd/system/multi-user.target.wants/firstboot-setup.service
}

validate_pubkey() {
    [[ -f $PUBKEY && -r $PUBKEY ]] || {
        echo "Public key not found or unreadable: ${PUBKEY}" >&2
        exit 1
    }

    # Prevent passing a private key
    if grep -q 'PRIVATE KEY' "${PUBKEY}"; then
        echo "That looks like a PRIVATE key. Pass the .pub file." >&2
        exit 1
    fi
}

install_pubkey() {
    [[ -n $1 ]] || {
        echo "install_pubkey receive no pubkey path"
        exit 1
    }

    local pubkey=$1
    local key_path="root/root/.ssh"

    # Create the .ssh path for root
    sudo mkdir -p "${key_path}"
    sudo chown root:root "${key_path}"
    sudo chmod 700 "${key_path}"

    # Install the key into the authorized_keys
    sudo install -D -m 0600 -o root -g root "${pubkey}" "${key_path}/authorized_keys"
    local ssh_policy="# Written by raspi installer: key-only SSH for default accounts.
Match User root,alarm
    PermitRootLogin prohibit-password
    PasswordAuthentication no
    KbdInteractiveAuthentication no
"

    printf '\n%s' "${ssh_policy}" | sudo tee -a root/etc/ssh/sshd_config > /dev/null
}

remove_alarm_user() {
    sudo sed -i '/^alarm:/d' root/etc/passwd root/etc/shadow root/etc/group root/etc/gshadow
    # Strip alarm from supplementary group member lists (wheel, etc.)
    sudo sed -i -E -e 's/:alarm$/:/' -e 's/:alarm,/:/' -e 's/,alarm(,|$)/\1/' root/etc/group root/etc/gshadow
    sudo rm -rf root/home/alarm || exit 1
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
    echo "The default usernames and passwords are"
    echo "Username: alarm"
    echo "Password: alarm"
    echo
    echo "root pass: root"
    echo
    echo "This may be different if you have asked the script to remove alarm or"
    echo "set an ssh key for the root login".
    echo ""
    echo "Once you have logged in, be sure to init/populate the archlinux keyring"
    echo "pacman-key --init && pacman-key --populate archlinuxarm"


    sudo rm -rf boot
    sudo rm -rf root

}



###############################################################################
# Install Process
##############################################################################
if [[ -n $PUBKEY ]]; then
    validate_pubkey
fi

if [[ -n $SETUP_SCRIPT ]]; then
     [[ -f $SETUP_SCRIPT && -r $SETUP_SCRIPT ]] || {
        echo "Setup script not found or unreadable: ${SETUP_SCRIPT}" >&2
        exit 1
    }
fi

download_packages

if [[ -z $SELECTED_DEVICE ]]; then
    get_devices DEVICES DEVICE_TYPE
    select_device SELECTED_DEVICE DEVICES
fi

echo "Using ${SELECTED_DEVICE}"

if ! $NOCONFIRM; then
    echo "Is this correct? y/n"
    read -r confirmation

    if [ "$confirmation" != "y" ]; then
        echo "Exiting..."
        exit 1
    fi
fi

format_device $SELECTED_DEVICE
get_boot_and_root_partition $SELECTED_DEVICE BOOT_PARTITION ROOT_PARTITION $DEVICE_TYPE

format_partitions $BOOT_PARTITION $ROOT_PARTITION
install_archlinux

# Install the setup script if a script was specified
if [[ -n $SETUP_SCRIPT ]]; then
    install_setup_script "${SETUP_SCRIPT}"
fi

if [[ -n $PUBKEY ]]; then
    install_pubkey "${PUBKEY}"
fi

if $REMOVE_ALARM; then
    remove_alarm_user
fi

cleanup $BOOT_PARTITION $ROOT_PARTITION
exit 0
