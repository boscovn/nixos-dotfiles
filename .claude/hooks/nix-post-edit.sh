#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): formats an edited .nix file with nixfmt (what
# `nix fmt` runs), reports a parse error back to Claude, and reminds it to
# `git add` a file the flake can't see yet.
set -u
file=$(jq -r '.tool_input.file_path // empty')
[[ $file == *.nix && -f $file ]] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
case $file in "$CLAUDE_PROJECT_DIR"/*) ;; *) exit 0 ;; esac

if ! err=$(nixfmt "$file" 2>&1); then
  echo "nixfmt failed on $file:" >&2
  echo "$err" >&2
  exit 2
fi

rel=${file#"$CLAUDE_PROJECT_DIR"/}
if [[ -z $(git ls-files -- "$rel") ]] && ! git check-ignore -q -- "$rel"; then
  jq -n --arg f "$rel" '{hookSpecificOutput: {hookEventName: "PostToolUse",
    additionalContext: "\($f) is untracked: the flake will not see it until it is staged (git add \($f))."}}'
fi
