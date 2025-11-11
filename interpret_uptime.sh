#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
用法: interpret_uptime.sh [uptime输出字符串]

若未提供参数，则脚本会直接调用系统的uptime命令并解读结果。
若提供参数，则视为一次完整的uptime输出并据此给出解读。
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  echo "参数数量错误。" >&2
  usage >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  raw_output=$1
else
  raw_output=$(uptime)
fi

trim() {
  local trimmed=$1
  trimmed=${trimmed#"${trimmed%%[![:space:]]*}"}  # 去掉前导空白
  trimmed=${trimmed%"${trimmed##*[![:space:]]}"}  # 去掉尾部空白
  printf '%s' "$trimmed"
}

current_time=$(trim "$(awk -F ' up ' 'NR==1 {print $1}' <<< "$raw_output")")

after_up=${raw_output#* up }
runtime_segment=$(trim "${after_up%%,*}")

remaining=${after_up#*, }
users_segment=$(trim "${remaining%%,*}")
users_count=$(awk '{print $1}' <<< "$users_segment")

load_segment=$(awk 'BEGIN{FS="load average: "}{if (NF>1){print $2}}' <<< "$raw_output")
if [[ -z $load_segment ]]; then
  load_segment=$(awk 'BEGIN{FS="load averages: "}{if (NF>1){print $2}}' <<< "$raw_output")
fi
load_segment=$(trim "$load_segment")

if [[ -z $current_time || -z $runtime_segment || -z $users_count || -z $load_segment ]]; then
  echo "无法完整解析输入，请检查uptime输出格式。" >&2
  exit 1
fi

echo "原始输出: $raw_output"
echo "解读:"
echo "  - 当前时间: $current_time"
echo "  - 系统已连续运行: $runtime_segment"
echo "  - 当前登录用户数: ${users_count} 个"
echo "  - 系统负载(1/5/15 分钟): $load_segment"

