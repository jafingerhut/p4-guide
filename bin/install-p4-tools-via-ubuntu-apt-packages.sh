#! /bin/bash

set -e

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

get_used_disk_space_in_mbytes() {
    echo $(df --output=used --block-size=1M . | tail -n 1)
}

linux_version_warning() {
    1>&2 echo "Found ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"
    1>&2 echo "This script only supports these:"
    1>&2 echo "    ID ubuntu, VERSION_ID in 22.04 24.04"
}

DISK_USED_START=`get_used_disk_space_in_mbytes`

if [ ! -r /etc/os-release ]
then
    1>&2 echo "No file /etc/os-release.  Cannot determine what OS this is."
    linux_version_warning
    exit 1
fi
source /etc/os-release

supported_distribution=0
if [ "${ID}" = "ubuntu" ]
then
    case "${VERSION_ID}" in
        22.04)
            supported_distribution=1
            ;;
        24.04)
            supported_distribution=1
            ;;
    esac
fi

if [ ${supported_distribution} -eq 1 ]
then
    echo "Found supported ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"
else
    linux_version_warning
    exit 1
fi

sudo apt-get --yes install git curl python3-pip python3-venv

PYTHON_VENV="${INSTALL_DIR}/p4dev-python-venv"
python3 -m venv "${PYTHON_VENV}"
source "${PYTHON_VENV}/bin/activate"


# Install open source P4 development tools via Debian packages

echo "deb http://download.opensuse.org/repositories/home:/p4lang:/latest/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/home:p4lang:latest.list
curl -fsSL https://download.opensuse.org/repositories/home:p4lang:latest/xUbuntu_${VERSION_ID}/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_p4lang_latest.gpg > /dev/null
sudo apt update
sudo apt --yes install p4lang-p4c p4lang-bmv2


# Install Mininet

cd "${INSTALL_DIR}"

# Pin to a particular version, so that I know the patch below will
# continue to apply.  Will likely want to update this to newer
# versions once or twice a year.
MININET_COMMIT="6eb8973c0bfd13c25c244a3871130c5e36b5fbd7"  # 2024-Sep-18
git clone https://github.com/mininet/mininet mininet
cd mininet
git checkout ${MININET_COMMIT}
PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"
patch -p1 < "${PATCH_DIR}/mininet-patch-for-2024-sep-enable-venv.patch"
cd ..
RESTORE_SUDOERS_FILE=0
if [ -e /etc/sudoers.d/sudoers-dotfiles ]
then
    # Starting with Ubuntu 24.04, by default it includes a sudo
    # configuration file that disallows passing environment variables
    # such as DEBIAN_FRONTEND on a sudo command line for apt-get
    # commands.  On such systems, temporarily rename this
    # configuration file while installing Mininet, since Mininet's
    # install script uses this feature of sudo.
    sudo mv /etc/sudoers.d/sudoers-dotfiles /etc/sudoers.d/sudoers-dotfiles.orig
    RESTORE_SUDOERS_FILE=1
fi
PYTHON=python3 ./mininet/util/install.sh -nw
if [ ${RESTORE_SUDOERS_FILE} -eq 1 ]
then
    sudo mv /etc/sudoers.d/sudoers-dotfiles.orig /etc/sudoers.d/sudoers-dotfiles
fi


# Other Python packages required for running tutorials exercises successfully

pip install p4runtime psutil crcmod

# Other Python packages required for running p4-guide/demo1 and other
# demo programs.

pip install ptf p4runtime-shell

DISK_USED_END=`get_used_disk_space_in_mbytes`

set +x
echo "All disk space utilizations below are in MBytes:"
echo ""
echo  "DISK_USED_START                ${DISK_USED_START}"
echo  "DISK_USED_END                  ${DISK_USED_END}"
echo  "DISK_USED_END - DISK_USED_START : $((${DISK_USED_END}-${DISK_USED_START})) MBytes"

echo "Run these commands in your shell's rc file, or at least in any shell where you want to use these tools:"
echo ""
echo "    source \"${PYTHON_VENV}/bin/activate\""
echo "    export P4_EXTRA_SUDO_OPTS=\"PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python\""
