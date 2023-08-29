#!/bin/bash -xeu

readonly PIPENV_VERSIONS=(
  2023.7.23 # Works
  # Ignore known broken versions.
  # 2023.8.19
  # 2023.8.20
  # 2023.8.21
  # 2023.8.22
  # 2023.8.26
  2023.8.28
)

check_pipfile() {
  local relative_package_path="${1}"
  local alternative_package_path=$(echo "${relative_package_path}" | \
                                     sed -r 's@^\./@@')
  local package_name=$(echo "${relative_package_path}" | \
                         sed -r 's@.*/([^/]+)@\1@')
  local error=0
  for filename in Pipfile Pipfile.lock; do
    local found_relative_package_path="$(\
      grep -F "\"${relative_package_path}" "${filename}")"
    local found_alternative_package_path="$(\
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
    echo "Installation of ${path} failed" >&2
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

main() {
  cd "$(dirname "$0")"
  for version in "${PIPENV_VERSIONS[@]}"; do
    pipx uninstall pipenv || true
    pipx install "pipenv==${version}"
    git clean -dfx
    git checkout Pipfile{,.lock} another_venv/Pipfile{,.lock}
    echo "=== Using pipenv version ${version} ==="
    pipenv sync
    if ! ( install_test_and_uninstall_package \
             . ./test-hello &&
           install_test_and_uninstall_package \
             . ./applications/test-hello &&
           install_test_and_uninstall_package \
             another_venv ./../test-hello &&
           install_test_and_uninstall_package \
             another_venv ./../applications/test-hello ); then
      echo "--- pipenv version ${version} is broken ---"
    else
      echo "--- pipenv version ${version} is working ---"
    fi
  done
}

main
