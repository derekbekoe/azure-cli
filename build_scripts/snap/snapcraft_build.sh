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

CLI_SNAPCRAFT_REPO=$1
CLI_SNAPCRAFT_BRANCH_TAG=$2

#define the template for snapcraft.yaml
cat  << EOF > $snapcraft_file
name: azure-cli
summary: Microsoft Azure CLI 2.0
description: |
 A great cloud needs great tools; we're excited to introduce Azure CLI 2.0, our
 next generation multi-platform command line experience for Azure.
version: "$CLI_VERSION"
confinement: classic
grade: stable
apps:
  az:
    command: usr/bin/python -m azure.cli
    completer: build_scripts/snap/az.snap.completion
parts:
  completion:
    plugin: dump
    source-type: git
    source: $CLI_SNAPCRAFT_REPO
    source-branch: $CLI_SNAPCRAFT_BRANCH_TAG
    stage:
      - build_scripts/snap/az.snap.completion
  azure-cli:
    plugin: python
    source-type: git
    source: $CLI_SNAPCRAFT_REPO
    source-branch: $CLI_SNAPCRAFT_BRANCH_TAG
    source-subdir: src/azure-cli
    python-version: python3
    organize:
      # PEP 394 says you should use python3, but the client uses python.
      usr/bin/python3.5: "usr/bin/python"
    build-packages:
      - build-essential
      - python3-dev
      - python3-wheel
      - libffi-dev
      - libssl-dev
    prepare: |
       set -e
       packages_dir="$(readlink -e ../packages)"
       /usr/bin/pip3 wheel -w $packages_dir src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*

EOF

echo 'snapcraft.yaml written to $snapcraft_file'

cat $snapcraft_file

cd $build_dir && snapcraft --version && snapcraft && cd -
$snap_file=$build_dir/azure-cli_${CLI_VERSION}_amd64.snap
cp $snap_file ${BUILD_ARTIFACT_DIR}
echo "Done."
