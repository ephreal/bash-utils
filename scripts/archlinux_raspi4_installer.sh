# Leave just ONE of these uncommented to choose your raspi archlinux version
#arch_ver=ArchLinuxARM-rpi-aarch64-latest.tar.gz
arch_ver=ArchLinuxARM-rpi-4-latest.tar.gz

# Decides what block devices the script will search for as valid installabl
# devices
# Valid options:
# sd-card
# block

dev="sd-card"

if [ $dev == "sd-card" ]
then
    devs=$(ls /dev | grep ^mmcblk[0-9]*$)
elif [ $dev == "block" ]
then
    devs=($(ls /dev | grep ^sd[a-z]$))
else
    echo "Invalid device option selected."
    exit 0
fi

counter=1

for dev in ${devs[@]}; do
    echo "$counter) $dev"
    counter=$(($counter + 1))
done

echo "Which device do you want to use?"
read dev
device=$((dev - 1))
echo "Using /dev/${devs[$device]}"
echo "Please confirm: y/n"
read confirmation

if [ $confirmation == "n" ]; then
    exit
fi

device=${devs[$device]}
sudo umount /dev/$device?*

# This part looks a little weird because fdisk accepts input directly from the stdin
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk /dev/$device
    o # New Partition Table
    n # New partition
    p # Primary Partition 
    1 # Partition number 1
      # Confirm default start position (newline)
    +200M # Make partition 1 200M in size
    t # Set the partition type
    c # Choose the partition type W95 FAT32
    n # New partition
    p # Primary partition type
    2 # Partition number 2
      # 2 newlines twice to make the partition as big as the entire remaining space
      # Newline 2
    w # Write the changes
EOF

# Create boot partition
if [ $dev == "sd-card" ]
then
    boot="/dev/$(echo $device)p1"
else
    boot="/dev/$(echo $device)1"
fi

# Ensure boot is unmounted. Some desktop environments automatically mount partitions
umount $boot
echo $boot
sudo mkfs.vfat $boot
mkdir boot
sudo mount $boot boot

# Create root partition
if [ $dev == "sd-card" ]
then
    root="/dev/$(echo $device)p2" 
else
    root="/dev/$(echo $device)2"
fi

umount $root
sudo mkfs.ext4 $root
mkdir root
sudo mount $root root

if [ ! -f $arch_ver ]; then
    wget http://os.archlinuxarm.org/os/$arch_ver
fi

sudo bsdtar -xpf $arch_ver -C root
sudo sync

sudo mv root/boot/* boot/

if [ "$arch_ver" == "ArchLinuxARM-rpi-aarch64-latest.tar.gz" ]; then
    sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab
fi

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
