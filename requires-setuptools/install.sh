#!/bin/bash -eu
# Flip PIP_NO_BUILD_ISOLATION to 1 fix the installation with pipenv 2023.9.7
export PIP_NO_BUILD_ISOLATION=0;
export PIPENV_SKIP_LOCK=true;
export PIPENV_VENV_IN_PROJECT=true;
cd "$(cd "$(dirname "${0}")"; pwd)/.."
git clean -dfx
pipenv --python "$(command -v python)"
declare -a pipenv_install_args=()
for i in $(seq 1 50); do
  package_name=requires-setuptools$((i))
  cp -r ./requires-setuptools "./${package_name}"
  sed -i "s/requires-setuptools/${package_name}/g" \
      "./${package_name}/setup.py"
  pipenv_install_args+=('-e' "./${package_name}")
done
set -x
export PIP_LOG_FILE=/dev/stdout
pipenv install "${pipenv_install_args[@]}"
pipenv lock
pipenv sync
