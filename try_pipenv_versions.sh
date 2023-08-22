#!/bin/bash -xeu

readonly PIPENV_VERSIONS=(
  2023.7.23
  2023.8.19
  2023.8.20
  2023.8.21
  2023.8.22
)

install_test_and_uninstall_package() {
  path="${1}"
  if ! pipenv run pipenv install -e "${path}"; then
    echo "Installation of ${path} failed" >&2
    return 1
  fi
  if ! pipenv run test-hello; then
    echo 'Execution of test-hello failed.' >&2
    return 1
  fi
  if ! pipenv uninstall test-hello; then
    echo 'Uninstallation of test-hello failed.'
    return 1
  fi
  return 0
}

main() {
  cd "$(dirname "$0")"
  for version in "${PIPENV_VERSIONS[@]}"; do
    pipx uninstall pipenv || true
    pipx install "pipenv==${version}"
    git clean -dfx
    echo "=== Using pipenv version ${version} ==="
    pipenv sync
    if ! ( install_test_and_uninstall_package ./test-hello &&
             install_test_and_uninstall_package ./applications/test-hello ); then
      echo "--- pipenv version ${version} is broken ---"
    else
      echo "--- pipenv version ${version} is working ---"
    fi
  done
}

main
