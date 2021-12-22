
check_patch_dirs_exist() {
    local abort_script
    abort_script=0
    for dir in $*
    do
	if [ -d "${dir}" ]
	then
	    echo "Found directory containing patches: ${dir}"
	else
	    echo "NO directory containing patches: ${dir}"
	    abort_script=1
	fi
    done
    
    if [ "${abort_script}" == 1 ]
    then
	echo ""
	echo "Aborting script because an expected directory does not exist (see above)."
	echo ""
	echo "This script is not designed to work if you only copy the"
	echo "script file to a system.  You should run it in the context"
	echo "of a cloned copy of the repository: https://github/jafingerhut/p4-guide"
	exit 1
    fi
}

clean_up() {
    local_child_process_pid=$1

    echo "Killing child process with PID ${local_child_process_pid}"
    ps uwwww ${local_child_process_pid}
    kill ${local_child_process_pid}
    # Invalidate the user's cached credentials
    sudo --reset-timestamp
    exit
}
