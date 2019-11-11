#! /bin/bash

echo "Disk space before installing docker"
date
df -BM .

# Prerequisite: docker has already been installed

git clone https://github.com/p4lang/p4runtime-shell
cd p4runtime-shell
docker build -t p4lang/p4runtime-sh .

echo "Disk space after installing docker"
date
df -BM .
