#! /bin/bash

print_usage() {
    1>&2 echo "usage: $0 [ <venv-root-directory> ]"
    1>&2 echo ""
}

if [ $# -ne 1 ]
then
    print_usage
    exit 1
fi

PYTHON_VENV="$1"
# Create a new Python virtual environment using venv.
sudo apt-get --yes install python3-venv
mkdir -p ${PYTHON_VENV}
python3 -m venv "${PYTHON_VENV}"

echo "To use the venv at ${PYTHON_VENV}, use the following command in a Bash shel:"
echo ""
echo "    source ${PYTHON_VENV}/bin/activate"
