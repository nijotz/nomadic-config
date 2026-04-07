#!/usr/bin/env bash
# Claude Code status line
# Receives session JSON on stdin; outputs a formatted status string.

json=$(cat)

if ! command -v jq &>/dev/null; then
  echo "[install jq for status line]"
  exit 0
fi

cwd=$(jq -r '.worktree.original_cwd // .workspace.project_dir // .cwd // ""' <<<"$json")
worktree_path=$(jq -r '.worktree.path // ""' <<<"$json")
worktree_name=$(jq -r '.worktree.name // ""' <<<"$json")
ctx_pct=$(jq -r '(.context_window.used_percentage // 0) | floor' <<<"$json")
model=$(jq -r '.model.display_name // ""' <<<"$json")
rate_5h=$(jq -r '(.rate_limits.five_hour.used_percentage // 0) | floor' <<<"$json")
rate_7d=$(jq -r '(.rate_limits.seven_day.used_percentage // 0) | floor' <<<"$json")
cost=$(printf '%.2f' "$(jq -r '.cost.total_cost_usd // 0' <<<"$json")")

# Git branch: use worktree path if available, otherwise project dir
if [[ -n "$worktree_path" ]]; then
  branch=$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)
else
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || true)
fi

# Shorten path relative to HOME
short_cwd="${cwd/#$HOME/\~}"

# ANSI colors
RED='\033[31m'
GRN='\033[32m'
YLW='\033[33m'
MAG='\033[35m'
CYN='\033[36m'
GRY='\033[90m'
RST='\033[0m'

SEP=" ${GRY}|${RST} "

parts=()

# Working directory
parts+=("${CYN}${short_cwd}${RST}")

# Git branch (+ worktree badge)
if [[ -n "$branch" ]]; then
  branch_part="${MAG}⎇ ${branch}${RST}"
  if [[ -n "$worktree_name" ]]; then
    branch_part+=" ${GRY}[wt:${worktree_name}]${RST}"
  fi
  parts+=("$branch_part")
fi

# Context usage (color shifts at 60% and 80%)
if [[ "$ctx_pct" -gt 0 ]]; then
  if [[ "$ctx_pct" -ge 80 ]]; then
    ctx_color="$RED"
  elif [[ "$ctx_pct" -ge 60 ]]; then
    ctx_color="$YLW"
  else
    ctx_color="$GRN"
  fi
  parts+=("${ctx_color}ctx:${ctx_pct}%${RST}")
fi

# Rate limits (5h and 7d)
if [[ "$rate_5h" -gt 0 ]]; then
  if [[ "$rate_5h" -ge 80 ]]; then
    r5_color="$RED"
  elif [[ "$rate_5h" -ge 60 ]]; then
    r5_color="$YLW"
  else
    r5_color="$GRN"
  fi
  parts+=("${r5_color}5h:${rate_5h}%${RST}")
fi

if [[ "$rate_7d" -gt 0 ]]; then
  if [[ "$rate_7d" -ge 80 ]]; then
    r7_color="$RED"
  elif [[ "$rate_7d" -ge 60 ]]; then
    r7_color="$YLW"
  else
    r7_color="$GRN"
  fi
  parts+=("${r7_color}7d:${rate_7d}%${RST}")
fi

# Model
if [[ -n "$model" ]]; then
  parts+=("${GRY}${model}${RST}")
fi

# Session cost (informational; for subscriptions actual usage is gated by rate limits)
if [[ "$cost" != "0" ]]; then
  parts+=("${GRY}\$${cost}${RST}")
fi

# Join parts with separator and print
out=""
for i in "${!parts[@]}"; do
  [[ $i -gt 0 ]] && out+="$SEP"
  out+="${parts[$i]}"
done

echo -e "$out"
