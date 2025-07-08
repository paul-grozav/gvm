# ============================================================================ #
# Author: Tancredi-Paul Grozav <paul@grozav.info>
# ============================================================================ #
should_debug=1 &&
# Uncomment to disable debugging
#should_debug=0 &&
# Start debugging
[ ${should_debug} -eq 1 ] && set -x || true &&

script_dir="$(cd $(dirname ${0}) ; pwd)" &&

# Select an operating system
bash ${script_dir}/os/ms-dos.sh &&

# Stop debugging
( [ ${should_debug} -eq 1 ] && set +x || true ) &&

true
# ============================================================================ #
