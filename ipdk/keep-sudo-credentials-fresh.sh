#! /bin/bash

# The only purpose of this script is to periodically execute 'sudo
# --validate', to update the user's cached credentials, in hopes that
# they only need to enter their password one time, not several times
# throughout the execution of a long-running bash script that executes
# 'sudo' commands to elevate privileges to run as the superuser every
# once in a while.

# With the default Ubuntu Linux configuration of caching credentials
# so that they need only be entered once every 15 minutes, running
# 'sudo --validate' once every minute is more than enough, but also
# very light-weight on CPU resources.

# At least on one Ubuntu 18.04 Linux system I tested on, the time
# stamp on the file /run/sudo/ts/$USER is the one that is updated to
# the current time when 'sudo --validate' is executed, or any other
# successful 'sudo' command.  It is the time stamp that is checked
# when 'sudo' is run to see if it is older than 15 minutes, or newer,
# requiring the password to be entered if it is older than 15 minutes
# ago.

# Running the command 'sudo -k' in my experiments did not remove that
# file.  It does change the contents of that file in some way that I
# haven't looked into the details of, in such a way that the next
# 'sudo' command entered by the user will require their password
# (again, all of this behavior is with the default Ubuntu Linux 18.04
# installation -- that configuration can certainly be changed after
# the OS is installed).

while true
do
    sudo --validate
    sleep 60
done
