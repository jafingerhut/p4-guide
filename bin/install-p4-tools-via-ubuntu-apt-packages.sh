#! /bin/bash

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

sudo apt-get --yes install git curl python3-pip python3-venv

PYTHON_VENV="${INSTALL_DIR}/p4dev-python-venv"
python3 -m venv "${PYTHON_VENV}"
source "${PYTHON_VENV}/bin/activate"


# Install open source P4 development tools via Debian packages

echo 'deb http://download.opensuse.org/repositories/home:/p4lang:/latest/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:p4lang:latest.list
curl -fsSL https://download.opensuse.org/repositories/home:p4lang:latest/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_p4lang_latest.gpg > /dev/null
sudo apt update
sudo apt install p4lang-p4c p4lang-bmv2


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

pip install p4runtime-shell

echo "Define this environment variable to enable P4 tutorials to run:"
echo ""
echo "    export P4_EXTRA_SUDO_OPTS=\"PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python\""
