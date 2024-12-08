#! /bin/bash

# First install rustup for Rust development.
# https://rustup.rs

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Then install x4c

cargo install --git https://github.com/oxidecomputer/p4 x4c
