#!/bin/bash -xeu

readonly PIPENV_VERSIONS=(
  2023.7.23
  # Ignore known broken versions.
  # 2023.8.19
  # 2023.8.20
  # 2023.8.21
  # 2023.8.22
  2023.8.26
)

install_test_and_uninstall_package() {
  local venv_path="${1}"
  local package_path="${2}"
  local error=0
  pushd "${venv_path}"
  if ! pipenv run pipenv install -e "${package_path}"; then
    echo "Installation of ${path} failed" >&2
    error=1
  elif ! pipenv run test-hello; then
    echo 'Execution of test-hello failed.' >&2
    error=1
  elif ! pipenv uninstall test-hello; then
    echo 'Uninstallation of test-hello failed.'
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
    echo "=== Using pipenv version ${version} ==="
    pipenv sync
    if ! ( install_test_and_uninstall_package \
             . ./test-hello &&
           install_test_and_uninstall_package \
             . ./applications/test-hello &&
           install_test_and_uninstall_package \
             another_venv ../test-hello &&
           install_test_and_uninstall_package \
             another_venv ../applications/test-hello ); then
      echo "--- pipenv version ${version} is broken ---"
    else
      echo "--- pipenv version ${version} is working ---"
    fi
  done
}

main
