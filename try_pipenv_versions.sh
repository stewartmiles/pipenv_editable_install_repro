#!/bin/bash -xeu

readonly PIPENV_VERSIONS=(
  2023.7.23 # Works
  # Ignore known broken versions.
  # 2023.8.19
  # 2023.8.20
  # 2023.8.21
  # 2023.8.22
  # 2023.8.26
  # 2023.8.28
  2023.9.1
)

# Written into .env before each set of executed tests.
readonly DOTENV=(
  ""

  # Add a local directory for wheel search.
  "PIP_FIND_LINKS=${PWD}/wheels
"

  # Also, disable pip build isolation to allow editable packages to depend upon
  # each other at build time.
  "PIP_FIND_LINKS=${PWD}/wheels
PIP_NO_BUILD_ISOLATION=0
"
  
  # Also, disable locking so that multiple packages can be installed using
  # pipenv install time and the all locked at once.
  "PIP_FIND_LINKS=${PWD}/wheels
PIP_NO_BUILD_ISOLATION=0
PIPENV_SKIP_LOCK=true
"
)

check_pipfile() {
  local relative_package_path="${1}"
  local alternative_package_path
  alternative_package_path=$(echo "${relative_package_path}" | \
                               sed -r 's@^\./@@')
  local error=0
  for filename in Pipfile Pipfile.lock; do
    local found_relative_package_path
    found_relative_package_path="$(\
      grep -F "\"${relative_package_path}" "${filename}")"
    local found_alternative_package_path
    found_alternative_package_path="$(\
      grep -F "\"${alternative_package_path}" "${filename}")"
    if [[ -z "${found_relative_package_path}" &&
          -z "${found_alternative_package_path}" ]]; then
      echo "${relative_package_path} and ${alternative_package_path} " >&2
      echo "not found in {filename}" >&2
      echo "--- ${filename} ---" >&2
      cat "${filename}" >&2
      error=1
    fi
  done
  return $((error))
}

install_test_and_uninstall_package() {
  local venv_path="${1}"
  local package_path="${2}"
  local error=0
  pushd "${venv_path}"
  if ! pipenv run pipenv install -e "${package_path}"; then
    echo "Installation of ${package_path} failed" >&2
    error=1
  elif ! check_pipfile "${package_path}"; then
    error=1
  elif ! pipenv run test-hello; then
    echo 'Execution of test-hello failed.' >&2
    error=1
  elif ! pipenv uninstall test-hello; then
    echo 'Uninstallation of test-hello failed.' >&2
    error=1
  fi
  popd
  return $((error))
}

make_venv() {
  local venv_directory="${1}"
  local dotenv_contents="${2}"
  mkdir -p "${venv_directory}"
  (
    cd "${venv_directory}"
    pwd
    echo -e "${dotenv_contents}" > .env
    pipenv --python "$(command -v python)"
  )
}

main() {
  cd "$(dirname "$0")"
  for version in "${PIPENV_VERSIONS[@]}"; do
    pipx uninstall pipenv || true
    pipx install "pipenv==${version}"
    echo "=== Using pipenv version ${version} ==="

    for dotenv_contents in "${DOTENV[@]}"; do
      git clean -dfx
      echo -e "--- Using .env---\n${dotenv_contents}"

      local venv_directory
      local relative_root_directory
      for vars in 'venv_directory=.; relative_root_directory=.' \
                  'venv_directory=another_venv; relative_root_directory=..'; do
        eval "${vars}"
        echo "--- Installing packages in ${venv_directory} ---"
        # NOTE: To nest these, venvs in subdirectories need to be created first
        # otherwise pipenv walks the parent tree and finds the wrong venv.
        make_venv "${venv_directory}" "${dotenv_contents}"

        # Test package installation.
        if ! ( install_test_and_uninstall_package \
                 "${venv_directory}" \
                 "${relative_root_directory}/test-hello" && \
               install_test_and_uninstall_package \
                 "${venv_directory}" \
                 "${relative_root_directory}/applications/test-hello" ); then
          echo "--- pipenv version ${version} is broken ---"
          break
        else
          echo "--- pipenv version ${version} is working ---"
        fi
      done
    done
  done
}

main
