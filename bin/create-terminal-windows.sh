#! /bin/bash

# Nice to have separate terminal windows to watch what is going on.

# Upper left: bmv2/simpel_switch execution, with its debug logging to
# stdout/stderr
#gnome-terminal --geometry=80x21+0+0 --title=simple_switch
# Wider terminal is good for --log-console messages from simple_switch
#gnome-terminal --geometry=100x23+0+0 --title=simple_switch
gnome-terminal --geometry=100x23+540+0 --title=simple_switch &

# Upper right: tabs 'compile' for compiling P4 code,
# 'simple_switch_CLI' for running that process and installing table
# entries, and 'scapy' for sending packets
#gnome-terminal --geometry=80x21+700+0 --tab --title=compile --tab --title=simple_switch_CLI --tab --title=scapy
gnome-terminal --geometry=80x21+0+0 --tab --title=compile --tab --title=simple_switch_CLI --tab --title=scapy &

# Bottom left: tshark running on veth2
gnome-terminal --geometry=80x19+0+485 --title="port 0 veth2" &

# Bottom right: tshark running on veth4
gnome-terminal --geometry=80x19+700+485 --title="port 1 veth4" &
