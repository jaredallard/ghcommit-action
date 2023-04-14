#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# uncomment to debug these stubs:
# export GIT_STUB_DEBUG=/dev/tty
# export GHCOMMIT_STUB_DEBUG=/dev/tty

setup() {
  export GITHUB_WORKSPACE=/tmp
}

@test "parses git status output and generates correct flags for ghcommit" {
  local commit_message='msg'
  local repo='org/repo'
  local branch='main'
  local empty='false'
  local file_pattern='.'

  stub git \
    "config --global --add safe.directory $GITHUB_WORKSPACE : echo stubbed" \
    "status -s --porcelain=v1 -z -- . : cat ./tests/fixtures/test-1 | tr '\n' '\0'"

  stub ghcommit \
    '-b main -r org/repo -m msg --add=README.md --add=foo.txt --delete=\""a path with spaces oh joy/file.txt\"" : echo Success'

  run ./entrypoint.sh "$commit_message" "$repo" "$branch" "$empty" "$file_pattern"
  assert_success
  assert_output --partial "Success"
}

@test "no changes" {
  local commit_message='msg'
  local repo='org/repo'
  local branch='main'
  local empty='false'
  local file_pattern='.'

  stub git \
    "config --global --add safe.directory $GITHUB_WORKSPACE : echo stubbed" \
    "status -s --porcelain=v1 -z -- . : echo"

  run ./entrypoint.sh "$commit_message" "$repo" "$branch" "$empty" "$file_pattern"
  assert_success
  assert_output --partial "No changes detected"
}

@test "no changes with --empty flag creates empty commit" {
  local commit_message='msg'
  local repo='org/repo'
  local branch='main'
  local empty='true'
  local file_pattern='.'

  stub git \
    "config --global --add safe.directory $GITHUB_WORKSPACE : echo stubbed" \
    "status -s --porcelain=v1 -z -- . : echo"

  stub ghcommit \
    '-b main -r org/repo -m msg --empty : echo Success'

  run ./entrypoint.sh "$commit_message" "$repo" "$branch" "$empty" "$file_pattern"
  assert_success
  assert_output --partial "Success"
}
