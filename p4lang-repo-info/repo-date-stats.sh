#! /bin/bash

STARTDIR="${PWD}"

for repo in */*
do
    cd $repo
    echo "----------------------------------------"
    echo "Repository: ${repo}"
    $HOME/p4-guide/bin/git-commit-date-stats.sh
    cd "${STARTDIR}"
done
