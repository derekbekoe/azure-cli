#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
#---------------------------------------------------------------------------------------------

set -ex

: "${CLI_VERSION:?CLI_VERSION environment variable not set.}"

build_dir=$(mktemp -d)
snapcraft_filename='snapcraft.yaml'
snapcraft_file=$build_dir/$snapcraft_filename

if [ -z "$1" ]
  then
    echo "No argument supplied for Git repo."
    exit 1
fi

if [ -z "$2" ]
  then
    echo "No argument supplied for Git branch or tag."
    exit 1
fi

[ -z "$BUILD_ARTIFACT_DIR"] && BUILD_ARTIFACT_DIR=$(pwd)

CLI_SNAPCRAFT_REPO=$1
CLI_SNAPCRAFT_BRANCH_TAG=$2

#define the template for snapcraft.yaml
cat  << 'EOF' > $snapcraft_file
name: azure-cli
summary: Microsoft Azure CLI 2.0
description: |
 A great cloud needs great tools; we're excited to introduce Azure CLI 2.0, our
 next generation multi-platform command line experience for Azure.
version: "CLI_VERSION"
confinement: classic
grade: stable
apps:
  az:
    command: usr/bin/python -m azure.cli
    completer: az.completion
parts:
  azure-cli:
    plugin: python
    source-type: git
    source: CLI_SNAPCRAFT_REPO
    source-branch: CLI_SNAPCRAFT_BRANCH_TAG
    python-version: python3
    build-packages:
      - build-essential
      - python3-dev
      - python3-wheel
      - libffi-dev
      - libssl-dev
    requirements: requirements.txt
    install: |
      python_packages="src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli*"
      export PYTHONUSERBASE=$SNAPCRAFT_PART_INSTALL
      export PYTHONHOME=$SNAPCRAFT_PART_INSTALL/usr
      echo $SNAPCRAFT_PART_INSTALL/usr/bin/python3
      $SNAPCRAFT_PART_INSTALL/usr/bin/python3 -c 'import site; print("PYTHONUSERBASE set to {!r}".format(site.getuserbase()))'
      $SNAPCRAFT_PART_INSTALL/usr/bin/python3 -m pip install --user $python_packages
      $SNAPCRAFT_PART_INSTALL/usr/bin/python3 -m pip install --no-index --user src/azure-cli
      install build_scripts/snap/az.snap.completion $SNAPCRAFT_PART_INSTALL/az.completion
      # PEP 394 says you should use python3, but the client uses python.
      ln -s python3 $SNAPCRAFT_PART_INSTALL/usr/bin/python
EOF


sed -i "$snapcraft_file" \
  -e "s|CLI_VERSION|$CLI_VERSION|g" \
  -e "s|CLI_SNAPCRAFT_REPO|$CLI_SNAPCRAFT_REPO|g" \
  -e "s|CLI_SNAPCRAFT_BRANCH_TAG|$CLI_SNAPCRAFT_BRANCH_TAG|g"

echo 'snapcraft.yaml written to $snapcraft_file'

cat $snapcraft_file

cd $build_dir && snapcraft --version && snapcraft && cd -
snap_file=$build_dir/azure-cli_${CLI_VERSION}_amd64.snap
cp $snap_file ${BUILD_ARTIFACT_DIR}
echo "Done."
