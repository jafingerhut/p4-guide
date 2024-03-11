#!/usr/bin/env python3

# Copyright 2024 Andy Fingerhut (andy.fingerhut@gmail.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import logging
import time

import p4runtime_sh.shell as sh
import p4runtime_shell_utils as shu


######################################################################
# Configure logging
######################################################################

# Note: I am not an expert at configuring the Python logging library.
# Recommendations welcome on improvements here.

# TODO: Where do logging messages go when this program is executed?

logger = logging.getLogger(None)
ch = logging.StreamHandler()
logger.setLevel(logging.INFO)
#logger.setLevel(logging.DEBUG)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

global_data = {}

def setUp(grpc_addr='localhost:9559',
          p4info_txt_fname='flowcache.p4info.txt',
          p4prog_binary_fname='flowcache.json'):
    sh.setup(device_id=0,
             grpc_addr=grpc_addr,
             election_id=(0, 1), # (high_32bits, lo_32bits)
             config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname),
             verbose=False)
    logger.info("Loaded P4 program '%s' and P4Info '%s' into switch"
                "" % (p4prog_binary_fname, p4info_txt_fname))

def tearDown():
    sh.teardown()

setUp()
tearDown()
