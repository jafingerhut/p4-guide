#! /bin/bash

# Copyright 2019-present Cisco Systems, Inc.

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


# On Ubuntu 16.04 gnome-terminal no longer supports the --title option.
# mate-terminal does.
if [ `which mate-terminal` ]; then
    CMD=mate-terminal
elif [ `which gnome-terminal` ]; then
    CMD=gnome-terminal
else
    echo "Could note find gnome-terminal or mate-terminal in command path"
    exit 1
fi

# Nice to have separate terminal windows to watch what is going on.

# Upper left: 'compile' for doing 'make run' commands
${CMD} --geometry=74x19+0+0 --title="compile & run" --zoom=1.1 &

# Upper right: miscellaneous
${CMD} --geometry=74x19-0+0 --title="whatever" --zoom=1.1 &

# Bottom left: bash running on host h1
${CMD} --geometry=74x22+0-0 --title="h1 bash" --zoom=1.1 &

# Bottom right: bash running on host h2
${CMD} --geometry=74x22-0-0 --title="h2 bash" --zoom=1.1 &
