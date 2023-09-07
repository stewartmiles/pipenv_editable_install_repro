#!/bin/bash -eu
# Flip PIP_NO_BUILD_ISOLATION to 1 fix the installation with pipenv 2023.9.7
export PIP_NO_BUILD_ISOLATION=0;
export PIPENV_SKIP_LOCK=true;
export PIPENV_VENV_IN_PROJECT=true;
cd $(cd $(dirname "${0}"); pwd)/..
git clean -dfx
pipenv --python $(which python)
pipenv install -e ./requires-setuptools
pipenv lock
pipenv sync
