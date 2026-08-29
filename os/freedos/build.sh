#!/bin/bash
# ============================================================================ #
# Author: Tancredi-Paul Grozav <paul@grozav.info>
# ============================================================================ #
# boot hdd in
# qemu-system-x86_64 -m 256M -hda ../../../dosnethdd.img -display curses -machine graphics=off -net nic,model=ne2k_isa -net user
# ============================================================================ #
set -x &&

script_dir="$(cd $(dirname ${0}); pwd)" &&
bin_dir="/home/paul/data/binaries_h313/network/containers/http/boot/FreeDOS" &&

# Don't remove the folder itself, as that's mounted and will require a restart
#rm -rf ${bin_dir}/* &&


# ============================================================================ #
# Create FreeDOS floppy with custom autoexec.bat
# ============================================================================ #
mkdir -p ${bin_dir} &&
(
exit 0
if [ ! -f ${bin_dir}/FD.zip ]
then
  fd_url="https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/" &&
  fd_url="${fd_url}/distributions/1.4/FD14-LiveCD.zip" &&
  wget ${fd_url} -O ${bin_dir}/FD.zip
fi &&
if [ ! -f ${bin_dir}/FD_live.iso ]
then
  unzip ${bin_dir}/FD.zip -D ${bin_dir} &&
  mv ${bin_dir}/FD*LIVE.iso ${bin_dir}/FD_live.iso
fi &&
true
) &&



function create_floppy()
{
# Create a 30 MB FAT16 image (room for drivers)
dd if=/dev/zero of=${bin_dir}/dosnet.img bs=1K count=1440 &&
# apt-get install -y dosfstools mtools parted
#mkfs.msdos ${bin_dir}/dosnet.img &&
#mkfs.fat -F 16 ${bin_dir}/dosnet.img &&
#mkfs.vfat ${bin_dir}/dosnet.img &&
#mkfs.fat -F 16 -S 512 -C ${bin_dir}/dosnet.img 61440 &&
#mkfs.fat -F 16 -n FREEDOS ${bin_dir}/dosnet.img &&
# fdisk -l ${bin_dir}/dosnet.img &&
# prepare the MBR with CPU code that loads KERNEL.SYS and the BIOS parameter
# block (BPB). These are copied from FreeDOS floppy .img
mformat -f 1440 -C -B ${bin_dir}/FD14BOOT.img -i ${bin_dir}/dosnet.img :: &&
#mformat -i ${bin_dir}/dosnet.img -F :: &&
#dd if=${bin_dir}/FD14BOOT.img of=${bin_dir}/dosnet.img bs=512 count=1 conv=notrunc &&
#~/data/binaries_h313/network/containers/http/ms-sys-2.8.0/build/bin/ms-sys --mbrdos --force ${bin_dir}/dosnet.img &&

# mdir -i ${bin_dir}/FD14BOOT.img :: &&
#mcopy -no -i ${bin_dir}/FD14BOOT.img ::KERNEL.SYS -i ${bin_dir}/dosnet.img :: &&
# mdel -i ${bin_dir}/FD14BOOT.img ::FDAUTO.BAT &&

# This is the first one that starts running, and it will call command.com
mcopy -n -i ${bin_dir}/FD14BOOT.img ::KERNEL.SYS ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/KERNEL.SYS :: &&
rm ${bin_dir}/KERNEL.SYS &&

# Command.com runs autoexec.bat and returns to shell prompt
mcopy -n -i ${bin_dir}/FD14BOOT.img ::COMMAND.COM ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/COMMAND.COM :: &&
rm ${bin_dir}/COMMAND.COM &&

# auto commands
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/autoexec.bat :: &&

# Create folder for extra commands/programs available
mmd -i ${bin_dir}/dosnet.img ::FREEDOS &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/EDIT.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/EDIT.EXE ::FREEDOS &&
rm ${bin_dir}/EDIT.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/SYS.COM ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/SYS.COM ::FREEDOS &&
rm ${bin_dir}/SYS.COM &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FDISK.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/FDISK.EXE ::FREEDOS &&
rm ${bin_dir}/FDISK.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FORMAT.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/FORMAT.EXE ::FREEDOS &&
rm ${bin_dir}/FORMAT.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FDAPM.COM ${bin_dir} &&
mcopy -i ${bin_dir}/dosnet.img ${bin_dir}/FDAPM.COM ::FREEDOS &&
rm ${bin_dir}/FDAPM.COM &&

# https://archive.org/download/microsoft-lan-manager-microsoft-network-client/Microsoft%20Network%20Client%20for%20DOS%203.0%20German.zip
# podman run -it --rm -v dosnet.img:/dosnet.img:rw fedora:41
# sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# dnf install https://github.com/rpmsphere/noarch/raw/master/r/rpmsphere-release-38-1.noarch.rpm
# Show disk contents
mdir -i ${bin_dir}/dosnet.img :: &&
true
} &&
# ============================================================================ #



# ============================================================================ #
# Create FreeDOS HardDisk with custom autoexec.bat
# ============================================================================ #
function create_blank_dos_hdd()
{
  # Create a 30 MB FAT16 image (room for drivers)
  dd if=/dev/zero of=${bin_dir}/dosnethdd_blank.img bs=1M count=10 &&
  #mkfs.msdos ${bin_dir}/dosnethdd_blank.img &&
  parted -s ${bin_dir}/dosnethdd_blank.img mklabel msdos &&
  parted -s ${bin_dir}/dosnethdd_blank.img mkpart primary fat16 1M 10M &&
  parted -s ${bin_dir}/dosnethdd_blank.img set 1 boot on &&
  ( cat - <<EOF
set PATH=%PATH%;A:\FREEDOS;
echo YES | format C: /Q /S
fdapm poweroff
EOF
  ) > ${bin_dir}/autoexec.bat &&
  create_floppy &&
  rm ${bin_dir}/autoexec.bat &&

  qemu-system-x86_64 \
    -m 256M \
    -fda ${bin_dir}/dosnet.img \
    -hda ${bin_dir}/dosnethdd_blank.img \
    -display curses \
    -machine graphics=off \
    -boot a \
    &&
  true
} &&

if [ ! -f ${bin_dir}/dosnethdd_blank.img ]
then
  create_blank_dos_hdd
fi &&

# clean disk(replace by blank one)
cp ${bin_dir}/dosnethdd_blank.img ${bin_dir}/dosnethdd.img &&

offset=$(( 1 * 1024 * 1024 )) &&
#mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/msnet :: &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${HOME}/data/binaries_h313/network/containers/http/games/pre2demo :: &&

mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${script_dir}/fs/autoexec.bat :: &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${script_dir}/fs/config.sys :: &&

# Create folder for extra commands/programs available
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${script_dir}/fs/freedos :: &&
# mmd -i ${bin_dir}/dosnethdd.img@@${offset} ::FREEDOS &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/EDIT.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/EDIT.EXE ::FREEDOS &&
rm ${bin_dir}/EDIT.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/SYS.COM ${bin_dir} &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/SYS.COM ::FREEDOS &&
rm ${bin_dir}/SYS.COM &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FDISK.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/FDISK.EXE ::FREEDOS &&
rm ${bin_dir}/FDISK.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FORMAT.EXE ${bin_dir} &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/FORMAT.EXE ::FREEDOS &&
rm ${bin_dir}/FORMAT.EXE &&

mcopy -n -i ${bin_dir}/FD14BOOT.img ::FREEDOS/BIN/FDAPM.COM ${bin_dir} &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/FDAPM.COM ::FREEDOS &&
rm ${bin_dir}/FDAPM.COM &&

# Create folder for network client program
#mmd -i ${bin_dir}/dosnethdd.img@@${offset} ::NET &&
# Kernel driver for network, loaded by OS(config.sys) at boot
#mcopy -i ${bin_dir}/dosnethdd.img@@${offset} \
#  ${bin_dir}/msnet/custom_install/ifshlp.sys ::NET &&
# Using mTCP instead
if [ ! -f ${bin_dir}/mTCP.zip ]
then
  wget https://www.brutman.com/mTCP/download/mTCP_2025-01-10.zip \
    -O ${bin_dir}/mTCP.zip
fi &&

if [ ! -f ${bin_dir}/mtcp/dhcp.exe ]
then
  mkdir -p ${bin_dir}/mtcp &&
  unzip ${bin_dir}/mTCP.zip -d ${bin_dir}/mtcp
fi &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/mtcp :: &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${script_dir}/fs/mtcp/mtcp.cfg \
  ::mtcp &&
# mTCP needs NE2000 to initialize the network card before it can use it.
if [ ! -f ${bin_dir}/ne2000.com ]
then
  wget https://www.brutman.com/Device_Drivers/packet_drivers/NE2000.COM \
    -O ${bin_dir}/ne2000.com
fi &&
mcopy -i ${bin_dir}/dosnethdd.img@@${offset} ${bin_dir}/ne2000.com ::MTCP &&


mdir -i ${bin_dir}/dosnethdd.img@@${offset} :: &&
# ============================================================================ #



# ============================================================================ #
# Prepare Microsoft Network Client Version 3.0 for DOS
# ============================================================================ #
(
exit 0 ;
# Notes:
#mkdir msnet/custom_install &&

#wget https://archive.org/download/dosdrivers/DOS%20Drivers.zip &&
#unzip DOS_Drivers.zip &&
#cp DOS_Drivers/ifshlp.sys ../../custom_install/ifshlp.sys &&

# C:\NE2000.COM 0x60 &&
# Add to C:\MTCP.CFG:
# PACKETINT 0x60
# set MTCPCFG=C:\MTCP.CFG
# dhcp
#cd msnet/DISKS/DISK1 &&
#cp IFSHLP.SY_ ../../custom_install/ifshlp.sys &&
true
) &&
# ============================================================================ #



set +x &&
exit 0
# ============================================================================ #
