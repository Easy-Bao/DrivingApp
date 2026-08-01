#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "${repository_root}"

tracked_source_files() {
  git ls-files \
    ':!:*.lock' \
    ':!:*.png' \
    ':!:*.jpg' \
    ':!:*.jpeg' \
    ':!:*.webp' \
    ':!:*.gif' \
    ':!:*.ttf' \
    ':!:*.otf' \
    ':!:**/test/**' \
    ':!:**/tests/**'
}

check_conflict_markers() {
  local conflict_matches
  conflict_matches="$(
    tracked_source_files | xargs -r rg --line-number --fixed-strings \
      -e '<<<<<<< ' \
      -e '=======' \
      -e '>>>>>>> ' || true
  )"

  if [[ -n "${conflict_matches}" ]]; then
    echo "Merge conflict markers were found:" >&2
    echo "${conflict_matches}" >&2
    return 1
  fi
}

check_secret_like_values() {
  local secret_matches
  secret_matches="$(
    tracked_source_files | xargs -r rg --line-number --pcre2 \
      -e '(?i)(api[_-]?key|secret|access[_-]?token|refresh[_-]?token|jwt[_-]?secret)\s*[:=]\s*['"'"'"][^/'"'"'"][^'"'"'"]{15,}['"'"'"]' \
      -e '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' || true
  )"

  if [[ -n "${secret_matches}" ]]; then
    echo "Potential hardcoded secrets were found:" >&2
    echo "${secret_matches}" >&2
    return 1
  fi
}

check_flutter_resource_disposal() {
  local dart_files_with_resources
  local files_missing_dispose
  dart_files_with_resources="$(
    git ls-files 'apps/**/*.dart' 'packages/**/*.dart' \
      | xargs -r rg --files-with-matches \
        'TextEditingController\(|AnimationController\(|ScrollController\(|PageController\(|FocusNode\(|StreamSubscription<|StreamSubscription\?|Timer\(|PublishSubject<' || true
  )"

  if [[ -z "${dart_files_with_resources}" ]]; then
    return 0
  fi

  files_missing_dispose="$(
    while IFS= read -r dart_file; do
      if ! rg --quiet 'void dispose\(|Future<void> close\(|void close\(' "${dart_file}"; then
        echo "${dart_file}"
      fi
    done <<< "${dart_files_with_resources}"
  )"

  if [[ -n "${files_missing_dispose}" ]]; then
    echo "Possible Flutter resource leaks were found. These files allocate disposable resources without a dispose method:" >&2
    echo "${files_missing_dispose}" >&2
    return 1
  fi
}

check_conflict_markers
check_secret_like_values
check_flutter_resource_disposal

echo "Repository guard checks passed."
