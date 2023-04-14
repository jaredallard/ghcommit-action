#!/usr/bin/env bash

set -euo pipefail

COMMIT_MESSAGE="${1:?Missing commit_message input}"
REPO="${2:?Missing repo input}"
BRANCH="${3:?Missing branch input}"
EMPTY="${4:-false}"
FILE_PATTERN="${5:?Missing file_pattern input}"

git config --global --add safe.directory "$GITHUB_WORKSPACE"

adds=()
deletes=()

# shellcheck disable=SC2086
while IFS= read -r -d $'\0' line; do
  # Extract the status in the tree and status in the index (first two characters)
  index_status="${line:0:1}"
  tree_status="${line:1:1}"
  # Extract the filename by removing the first three characters (two statuses and a whitespace)
  filename="${line:3}"

  # Print the parsed information, useful for debugging
  echo "Index Status: $index_status"
  echo "Tree Status: $tree_status"
  echo "Filename: $filename"
  echo "-----------------------------"
  # https://git-scm.com/docs/git-status

  # handle adds (A), modifications (M), and type changes (T):
  [[ "$tree_status" =~ A|M|T || "$index_status" =~ A|M|T ]] && adds+=("$filename")

  # handle deletes (D):
  [[ "$tree_status" =~ D || "$index_status" =~ D ]] && deletes+=("$filename")

  # TODO: handle renames (R) and copies (C). Example rename status line:
  #   'R  main.sh -> main.sh.new'
done < <(git status -s --porcelain=v1 -z -- $FILE_PATTERN)

if [[ "${#adds[@]}" -eq 0 && "${#deletes[@]}" -eq 0 && "$EMPTY" == "false" ]]; then
  echo "No changes detected, exiting"
  exit 0
fi

ghcommit_args=()
ghcommit_args+=(-b "$BRANCH")
ghcommit_args+=(-r "$REPO")
ghcommit_args+=(-m "$COMMIT_MESSAGE")

if [[ "$EMPTY" =~ ^(true|1|yes)$ ]]; then
  ghcommit_args+=(--empty)
fi

ghcommit_args+=("${adds[@]/#/--add=}")
ghcommit_args+=("${deletes[@]/#/--delete=}")

ghcommit "${ghcommit_args[@]}"