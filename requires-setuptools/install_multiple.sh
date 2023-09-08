#!/bin/bash -eu
: "${INSTALL_PACKAGES:=50}"

export PIPENV_SKIP_LOCK=true;
export PIPENV_VENV_IN_PROJECT=true;
cd "$(cd "$(dirname "${0}")"; pwd)/.."
git clean -dfx
pipenv --python "$(command -v python)"
declare -a pipenv_install_args=()
for i in $(seq 1 $((INSTALL_PACKAGES))); do
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
