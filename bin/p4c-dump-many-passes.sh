#! /bin/bash

P4_SRC_FNAME="$1"

mkdir -p tmp
p4c-bm2-ss --dump tmp --top4 Front,Mid "${P4_SRC_FNAME}"
