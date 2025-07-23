#!/bin/zsh

#
# Copyright 2022-2025 Creek Contributors (https://github.com/creek-service)
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

# Installs the Z-shell scripts onto the local machine

SCRIPT_DIR=${0:a:h}/zsh-functions

echo >> ~/.zshrc
echo "# Root directory containing Creek repos:" >> ~/.zshrc
echo "CREEK_BASE_DIR=$(dirname $PWD)" >> ~/.zshrc
echo "Set CREEK_BASE_DIR to $(dirname $PWD)"

echo >> ~/.zshrc
echo "# Install Creek functions:" >> ~/.zshrc

find $SCRIPT_DIR -type d ! -empty -exec sh -c "
  echo "fpath+={}" >> ~/.zshrc
  echo added {} to fpath
  " \;

echo "autoload -Uz $SCRIPT_DIR/**/*(.:t)" >> ~/.zshrc
echo "typeset -U fpath" >> ~/.zshrc
source ~/.zshrc
