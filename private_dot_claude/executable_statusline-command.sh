#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

out=""
[ -n "$model" ] && out="$model"
if [ -n "$repo" ]; then
  [ -n "$out" ] && out="$out  |  "
  out="$out$repo"
fi
if [ -n "$remaining" ]; then
  [ -n "$out" ] && out="$out  |  "
  out="${out}ctx: $(printf '%.0f' "$remaining")%"
fi

echo "$out"
