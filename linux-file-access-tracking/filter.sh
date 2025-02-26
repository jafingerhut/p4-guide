#! /bin/bash

cat $1 | egrep -v '\bPROC= (systemd|top|tracker-extract|tracker-miner-f|wc|which|wireplumber|git|\(b-backup\)|\(ogrotate\)|\(sa[12]\)|\(sd-mkdcreds\)|\(sd-rmrf\)|\(tmpfiles\)|dbus-daemon|gnome-terminal-|systemd-oomd|VBoxClient|VBoxService|Xorg|9 )' | egrep -v ' PATH= (/proc/|/usr/share/locale)' | egrep -v '\.[sd]$'

