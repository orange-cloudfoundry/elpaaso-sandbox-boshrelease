#!/usr/bin/env bash
#
# Copyright (C) 2015 Orange
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
OUTPUT="$PWD/bosh-candidate-release"
VERSION="$(cat bosh-version/number)"

echo "DEBUG - OUTPUT: <$OUTPUT> - VERSION: <$VERSION>"

pushd elpaaso-sandbox-boshrelease
echo "DEBUG - pwd: $PWD"

  echo "Updating submodule"
  ./update

  echo "Creating bosh release"
  bosh -n create release --with-tarball --name elpaaso-sandbox-boshrelease --version "$VERSION"

  echo "Moving to OUTPUT"
  mv dev_releases/elpaaso-sandbox-boshrelease/elpaaso-sandbox-boshrelease-*.tgz "$OUTPUT"
popd
