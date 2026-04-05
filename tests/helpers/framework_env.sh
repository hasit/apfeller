#!/bin/sh

set -eu

setup_framework_env() {
  ROOT_DIR=$1
  TEST_TMP_DIR=$2
  TEST_DIST_DIR="$TEST_TMP_DIR/dist"
  TEST_CATALOG_PATH="$TEST_DIST_DIR/apfeller-catalog.tsv"
  TEST_HOME_DIR="$TEST_TMP_DIR/home"
  TEST_STUB_DIR="$TEST_TMP_DIR/bin"
  TEST_MANAGER_STAGE="$TEST_TMP_DIR/manager"

  mkdir -p "$TEST_STUB_DIR" "$TEST_MANAGER_STAGE" "$TEST_HOME_DIR/.local/bin" "$TEST_DIST_DIR"

  cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$TEST_STUB_DIR/apfel"
  chmod +x "$TEST_STUB_DIR/apfel"

  sh "$ROOT_DIR/scripts/package_release.sh" --output-dir "$TEST_DIST_DIR"
  sh "$ROOT_DIR/scripts/package_catalog.sh" \
    --output-dir "$TEST_DIST_DIR" \
    --app-dir "$ROOT_DIR/fixtures/apps" \
    --bundle-base-url "file://$TEST_DIST_DIR"

  tar -xzf "$TEST_DIST_DIR/apfeller.tar.gz" -C "$TEST_MANAGER_STAGE"
  cp "$TEST_MANAGER_STAGE/bin/apfeller" "$TEST_HOME_DIR/.local/bin/apfeller"
  chmod +x "$TEST_HOME_DIR/.local/bin/apfeller"
}

framework_run_manager() {
  HOME="$TEST_HOME_DIR" \
  PATH="$TEST_HOME_DIR/.local/bin:$TEST_STUB_DIR:$PATH" \
  APFELLER_CATALOG_URL="file://$TEST_CATALOG_PATH" \
  APFELLER_INSTALL_URL="file://$TEST_DIST_DIR/apfeller.tar.gz" \
  apfeller "$@"
}

framework_run_app() {
  HOME="$TEST_HOME_DIR" \
  PATH="$TEST_HOME_DIR/.local/bin:$TEST_STUB_DIR:$PATH" \
  "$@"
}
