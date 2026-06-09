#!/usr/bin/env bash

. scripts/cmd/clashctl.sh
. scripts/preflight.sh

_valid
_parse_args "$@"

_prepare_zip
_detect_init

_okcat "安装内核：$KERNEL_NAME by ${INIT_TYPE}"
_okcat '📦' "安装路径：$CLASH_BASE_DIR"

/bin/cp -rf . "$CLASH_BASE_DIR"
touch "$CLASH_CONFIG_BASE"
_set_envs
_is_regular_sudo && chown -R "$SUDO_USER" "$CLASH_BASE_DIR"

_install_service
_apply_rc


_merge_config
_detect_proxy_port
clashui
clashsecret "$(_get_random_val)" >/dev/null
clashsecret

clashtun off >/dev/null 2>&1
clashtun on

_okcat '🎉' '安装完成 🎉'
echo ""
echo "  快速使用："
echo "    clashnode test    # 测试所有节点延迟"
echo "    clashnode use     # 交互式选择节点"
echo ""
clashctl

_valid_config "$CLASH_CONFIG_BASE" && CLASH_CONFIG_URL="file://$CLASH_CONFIG_BASE"
_quit "clashsub add $CLASH_CONFIG_URL && clashsub use 1"
