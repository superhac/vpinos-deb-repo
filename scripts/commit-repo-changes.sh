#!/usr/bin/env bash
set -euo pipefail

message="${COMMIT_MESSAGE:-Update Debian repository}"
remote="${GIT_REMOTE:-origin}"
branch="${GIT_BRANCH:-${GITHUB_REF_NAME:-$(git branch --show-current)}}"
max_attempts="${PUSH_ATTEMPTS:-3}"

if [[ -z "$branch" ]]; then
  echo "Could not determine the git branch to push." >&2
  exit 1
fi

git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

has_repo_changes() {
  ! git diff --quiet -- pool repo ||
    [[ -n "$(git ls-files --others --exclude-standard pool repo)" ]]
}

sync_with_remote() {
  local stash_created=0

  if has_repo_changes; then
    git stash push --include-untracked -m "apt repo package changes" -- pool repo
    stash_created=1
  fi

  git pull --rebase "$remote" "$branch"

  if [[ "$stash_created" == "1" ]]; then
    git stash pop
  fi

  scripts/update-apt-repo.sh
}

sync_with_remote

git add pool repo

if git diff --cached --quiet; then
  echo "No package or repository metadata changes to commit."
  exit 0
fi

git commit -m "$message"

for attempt in $(seq 1 "$max_attempts"); do
  if git push "$remote" "HEAD:$branch"; then
    exit 0
  fi

  if [[ "$attempt" == "$max_attempts" ]]; then
    echo "Failed to push after $max_attempts attempts." >&2
    exit 1
  fi

  echo "Push rejected; syncing with $remote/$branch and retrying."
  git pull --rebase "$remote" "$branch"
  scripts/update-apt-repo.sh
  git add pool repo

  if ! git diff --cached --quiet; then
    git commit --amend --no-edit
  fi
done
