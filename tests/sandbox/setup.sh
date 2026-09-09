#!/usr/bin/env bash
# 搭建 clashnode 沙盒测试环境（bwrap 隔离，不影响 ~/clashctl 现役安装）
# 布局：$SB/home 作为沙盒内的 $HOME，含独立 clashctl 目录
set -euo pipefail

SB=/var/tmp/clash-sandbox
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LIVE="$HOME/clashctl"

[ -x "$LIVE/bin/mihomo" ] || { echo "需要现役安装 $LIVE 提供 mihomo/yq 二进制" >&2; exit 1; }

rm -rf "$SB"
mkdir -p "$SB/home/clashctl/bin" "$SB/home/clashctl/resources"
cp -r "$REPO/scripts" "$SB/home/clashctl/"
sed 's/^CLASHCTL_KERNEL=$/CLASHCTL_KERNEL=mihomo/; s/^INIT_TYPE=$/INIT_TYPE=nohup/' \
    "$REPO/.env" > "$SB/home/clashctl/.env"
cp "$LIVE/bin/mihomo" "$LIVE/bin/yq" "$SB/home/clashctl/bin/"
cp "$LIVE/resources/Country.mmdb" "$LIVE/resources/geosite.dat" "$SB/home/clashctl/resources/"
cp "$HERE/runtime.yaml" "$SB/home/clashctl/resources/runtime.yaml"
printf 'secret: ""\n' > "$SB/home/clashctl/resources/mixin.yaml"
cat > "$SB/home/.bashrc" <<'EOF'
export CLASHCTL_HOME="$HOME/clashctl"
. "$CLASHCTL_HOME/scripts/cmd/clashctl.sh"
EOF
echo "沙盒就绪：$SB"
