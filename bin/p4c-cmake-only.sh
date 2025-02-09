#! /bin/bash

# Copyright 2019 Cisco Systems, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


# Only run cmake, which should be done from inside of the p4c/build
# directory.

# If you run this command, it will rescan the testdata/p4_16_samples
# and testdata/p4_14_samples (and other) directories, regenerating
# whatever files in the build directory exist and are used by future
# 'make check' runs.  Thus if you add new test programs in those
# testdata directories, running this 'cmake' command will cause future
# 'make check' runs to also run those tests.

# Configure for a debug build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG
# Copied from p4c/Dockerfile
#cmake .. '-DCMAKE_CXX_FLAGS:STRING=-O3'
