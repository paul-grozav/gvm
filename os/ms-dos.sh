# ============================================================================ #
# Author: Tancredi-Paul Grozav <paul@grozav.info>
# ============================================================================ #
# name: MS-DOS
# description: Microsoft Disk Operating System
# project_source: https://github.com/microsoft/MS-DOS
# ============================================================================ #
should_debug=1 &&
# Uncomment to disable debugging
#should_debug=0 &&
# Start debugging
[ ${should_debug} -eq 1 ] && set -x || true &&

scratch=0 &&
# scratch=1 &&
script_dir="$(cd $(dirname ${0}) ; pwd)" &&

input_socket="${script_dir}/vm-input.sock" &&
input_snd_client="socat - UNIX-CONNECT:${input_socket}" &&
input_socket="127.0.0.1:4444" &&
input_snd_client="socat - TCP:127.0.0.1:4444" &&

cdrom_file="${script_dir}/ms-dos.iso" &&
if [ ${scratch} -eq 1 ]
then
  rm -f ${cdrom_file}
fi &&

if [ ! -f ${cdrom_file} ]
then
  url="https://archive.org/download/ms-dos-6.22_dvd/MS-DOS%206.22.iso" &&
  url="https://archive.org/download/DOS6.22ISO/MS-DOS%206.22.iso" &&
  url="https://dl-alt1.winworldpc.com/Microsoft%20MS-DOS%206.22%20Plus%20Enhanced%20Tools%20(3.5).7z" &&
  wget ${url} -O ${cdrom_file} &&
  7z x ${cdrom_file} &&
  mv ${script_dir}/Microsoft\ MS-DOS\ 6.22\ Plus\ Enhanced\ Tools\ \(3.5\)/ \
    ${script_dir}/ms-dos-setup &&
  true
fi &&

# Create virtual disk
hdd_file="${script_dir}/vm.img" &&
if [ ${scratch} -eq 1 ]
then
  rm -f ${hdd_file}
fi &&
if [ ! -f ${hdd_file} ]
then
  qemu-img create -f qcow2 ${hdd_file} 50M
fi &&

qemu_pid="$( qemu-system-x86_64 \
  ` # RAM for the machine ` \
  -m 16M \
  ` # CPU cores for the machine ` \
  -smp 1 \
  ` # Using socket file to send commands to qemu console, and key strokes ` \
  ` # -monitor unix:"${input_socket}",server,nowait ` \
  -monitor tcp:${input_socket},server,nowait \
  ` # -monitor stdio ` \
  ` # -display curses ` \
  ` # -display none ` \
  -vnc :0 \
  ` # -machine graphics=off ` \
  ` # -serial stdio ` \
  -hda ${hdd_file} \
  ` # Mount ISO as CD-ROM ` \
  ` # -cdrom ${cdrom_file} ` \
  ` # Mount Floppy disk ` \
  -fda ${script_dir}/ms-dos-setup/Disk1.img \
  ` # Boot from CD-ROM ` \
  -boot a \
  1>/dev/null \
  2>&1 \
  &
  echo ${!} )" &&

# url="https://dl-alt1.winworldpc.com/Microsoft%20MS-DOS%206.22%20Plus%20Enhanced%20Tools%20(3.5).7z" &&
sleep 10 &&
# Start setup
#echo "quit" | ${input_snd_client} &&
echo "sendkey ret" | ${input_snd_client} &&
sleep 2 &&
# configure unallocated disk space
echo "sendkey ret" | ${input_snd_client} &&
sleep 2 &&
# setup will restart computer.ensure disk A is inserted in drive A
echo "sendkey ret" | ${input_snd_client} &&
# restarting machine and formatting disk C:
sleep 30 &&
# confirm configuration for OS
echo "sendkey ret" | ${input_snd_client} &&
sleep 3 &&
# confirm OS install directory C:\DOS
echo "sendkey ret" | ${input_snd_client} &&
# installing from floppy disk 1
sleep 40 &&
# insert and confirm floppy disk 2
echo "change floppy0 ${script_dir}/ms-dos-setup/Disk2.img" | ${input_snd_client} &&
sleep 1 &&
echo "sendkey ret" | ${input_snd_client} &&
# installing from floppy disk 2
sleep 40 &&
# insert and confirm floppy disk 3
echo "change floppy0 ${script_dir}/ms-dos-setup/Disk3.img" | ${input_snd_client} &&
sleep 1 &&
echo "sendkey ret" | ${input_snd_client} &&
# installing from floppy disk 1
sleep 40 &&
# eject floppy disk and confirm
echo "eject floppy0" | ${input_snd_client} &&
sleep 1 &&
echo "sendkey ret" | ${input_snd_client} &&
# restart machine
sleep 1 &&
echo "sendkey ret" | ${input_snd_client} &&
# stop machine
sleep 20 &&
echo "quit" | ${input_snd_client} &&

# Use mTCP to connect MS-DOS to the network and user FTP to fetch files into
# MS-DOS: https://www.brutman.com/mTCP/

(
  exit 0;
  dd if=/dev/zero of=tedi_manual_floppy.img bs=512 count=2880 &&
  mkfs.vfat tedi_manual_floppy.img &&
  fdisk -l tedi_manual_floppy.img &&
  mkdir floppy &&
  mount -o loop tedi_manual_floppy.img $(pwd)/floppy &&
  # Using mtools to read/write to MS-DOS floppy disks
  echo "drive a: file=\"$(pwd)/tedi_manual_floppy.img\" fat_bits=12" \
    > ${HOME}/.mtoolsrc &&
  # List files on floppy disk
  # mdir a: &&
  # mcopy file.txt a: &&
  # mcopy * a: &&
  true
) &&


# ============================================================================ #

# url="https://archive.org/download/ms-dos-6.22_dvd/MS-DOS%206.22.iso" &&
# This is only live - no way to install it

# url="https://archive.org/download/DOS6.22ISO/MS-DOS%206.22.iso" &&
# Installer can not find floppy disk
# sleep 7 &&
# # Select install and press enter
# echo "sendkey 3" | socat - UNIX-CONNECT:"${input_socket}" &&
# sleep 0.5 &&
# echo "sendkey ret" | socat - UNIX-CONNECT:"${input_socket}" &&
# # Wait for installer to start
# sleep 35 &&
# # Enter to start Setup
# echo "sendkey ret" | socat - UNIX-CONNECT:"${input_socket}" &&
# sleep 1 &&
# # Choose: Configure unallocated disk space (recommended)
# echo "sendkey ret" | socat - UNIX-CONNECT:"${input_socket}" &&
# # Press enter to pick up Setup Disk #1
# echo "sendkey ret" | socat - UNIX-CONNECT:"${input_socket}" &&

# sleep 5 &&
# kill -SIGTERM ${qemu_pid} &&
# wait ${qemu_pid} &&

# Stop debugging
( [ ${should_debug} -eq 1 ] && set +x || true ) &&

true 
# ============================================================================ #
