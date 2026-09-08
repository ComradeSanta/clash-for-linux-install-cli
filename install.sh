#!/usr/bin/env bash

CLASHCTL_SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
. "$CLASHCTL_SRC/scripts/preflight.sh"

valid_env
parse_args "$@"

_okcat "安装内核：$CLASHCTL_KERNEL"
_okcat '📦' "安装路径：$CLASHCTL_HOME"

prepare_zip

install_service
install_clashctl

_merge_config
_detect_proxy_port
clashui
[ -z "$(_get_secret)" ] && clashsecret "$(_get_random_val)" >/dev/null
clashsecret

clashtun off >/dev/null 2>&1
clashtun on

_okcat '🎉' '安装完成 🎉'
echo ""
echo "  快速使用："
echo "    clashnode delay   # 测试所有节点延迟"
echo "    clashnode use     # 交互式选择节点"
echo ""

_valid_config "$CLASH_CONFIG_BASE" && {
    CLASHCTL_SUB_URL="file://$CLASH_CONFIG_BASE"
}
clashsub add --use "$CLASHCTL_SUB_URL"
_okcat '🎉' "请执行 source ~/.bashrc 为当前 SHELL 加载 clashctl 命令"
