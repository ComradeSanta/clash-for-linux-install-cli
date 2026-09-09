#!/usr/bin/env bash
# 在 bwrap 沙盒中运行 clashnode 端到端测试
# 文件系统只读挂载，仅沙盒 HOME 可写；现役安装不受影响
set -euo pipefail

SB=/var/tmp/clash-sandbox
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"

[ -d "$SB" ] || "$HERE/setup.sh"

# 把仓库当前脚本同步进沙盒（保证测的是工作区代码）
rm -rf "$SB/home/clashctl/scripts"
cp -r "$REPO/scripts" "$SB/home/clashctl/"

exec bwrap \
    --ro-bind / / \
    --bind "$SB" "$SB" \
    --tmpfs /tmp \
    --bind "$SB/home" /home/arch \
    --ro-bind "$REPO" "$REPO" \
    --dev /dev --proc /proc \
    --setenv HOME /home/arch \
    --setenv TERM xterm-256color \
    -- bash "$HERE/driver.sh"
