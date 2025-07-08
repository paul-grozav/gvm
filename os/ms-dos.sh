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

cdrom_file="${script_dir}/ms-dos.iso" &&
if [ ${scratch} -eq 1 ]
then
  rm -f ${cdrom_file}
fi &&

if [ ! -f ${cdrom_file} ]
then
  wget https://archive.org/download/DOS6.22ISO/MS-DOS%206.22.iso \
    -O ${cdrom_file}
fi &&

# Create virtual disk
hdd_file="${script_dir}/vm.img" &&
qemu-img create -f qcow2 ${hdd_file} 4G &&

qemu-system-x86_64 \
  -m 16M \
  -smp 1 \
  ` # -display none ` \
  ` # -serial stdio ` \
  -hda ${hdd_file} \
  -cdrom ${cdrom_file} \
  &&

# Stop debugging
( [ ${should_debug} -eq 1 ] && set +x || true ) &&

true 
# ============================================================================ #
