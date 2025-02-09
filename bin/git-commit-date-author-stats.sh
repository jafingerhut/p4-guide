#! /bin/bash
# Copyright 2025 Andy Fingerhut
#
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


echo "Most recent commit:"
git log -n 1 | grep '^Date:'

echo ""
echo "Number of commits by year:"
echo "<# commits> <year>"
echo ""
git log . | grep '^Date:' | awk '{print $6;}' | sort | uniq -c

echo ""
echo "Number of commits by person, for most 10 frequent committers:"
echo "<# commits> <person>"
git log . | grep '^Author:' | sort | uniq -c | sort -n | tail -n 10
