#!/usr/bin/env bash

THIS_SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE:-${(%):-%N}}")")
. "$THIS_SCRIPT_DIR/common.sh"

_set_system_proxy() {
    local mixed_port=$("$BIN_YQ" '.mixed-port // ""' "$CLASH_CONFIG_RUNTIME")
    local http_port=$("$BIN_YQ" '.port // ""' "$CLASH_CONFIG_RUNTIME")
    local socks_port=$("$BIN_YQ" '.socks-port // ""' "$CLASH_CONFIG_RUNTIME")

    local auth=$("$BIN_YQ" '.authentication[0] // ""' "$CLASH_CONFIG_RUNTIME")
    [ -n "$auth" ] && auth=$auth@

    local bind_addr=$(_get_bind_addr)
    local http_proxy_addr="http://${auth}${bind_addr}:${http_port:-${mixed_port}}"
    local socks_proxy_addr="socks5h://${auth}${bind_addr}:${socks_port:-${mixed_port}}"
    local no_proxy_addr="localhost,127.0.0.1,::1"

    export http_proxy=$http_proxy_addr
    export HTTP_PROXY=$http_proxy

    export https_proxy=$http_proxy
    export HTTPS_PROXY=$https_proxy

    export all_proxy=$socks_proxy_addr
    export ALL_PROXY=$all_proxy

    export no_proxy=$no_proxy_addr
    export NO_PROXY=$no_proxy
}
_unset_system_proxy() {
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY
    unset no_proxy
    unset NO_PROXY
}
_detect_proxy_port() {
    local mixed_port=$("$BIN_YQ" '.mixed-port // ""' "$CLASH_CONFIG_RUNTIME")
    local http_port=$("$BIN_YQ" '.port // ""' "$CLASH_CONFIG_RUNTIME")
    local socks_port=$("$BIN_YQ" '.socks-port // ""' "$CLASH_CONFIG_RUNTIME")
    [ -z "$mixed_port" ] && [ -z "$http_port" ] && [ -z "$socks_port" ] && mixed_port=7890

    local newPort count=0
    local port_list=(
        "mixed_port|mixed-port"
        "http_port|port"
        "socks_port|socks-port"
    )
    clashstatus >&/dev/null && local isActive='true'
    for entry in "${port_list[@]}"; do
        local var_name="${entry%|*}"
        local yaml_key="${entry#*|}"

        eval "local var_val=\${$var_name}"

        [ -n "$var_val" ] && _is_port_used "$var_val" && [ "$isActive" != "true" ] && {
            newPort=$(_get_random_port)
            ((count++))
            _failcat '🎯' "端口冲突：[$yaml_key] $var_val 🎲 随机分配 $newPort"
            "$BIN_YQ" -i ".${yaml_key} = $newPort" "$CLASH_CONFIG_MIXIN"
        }
    done
    ((count)) && _merge_config
}

function clashon() {
    _detect_proxy_port
    clashstatus >&/dev/null || ( nohup $BIN_KERNEL -d $CLASH_RESOURCES_DIR -f $CLASH_CONFIG_RUNTIME > ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log 2>&1 & )
    clashstatus >&/dev/null || {
        _failcat '启动失败: 执行 clashlog 查看日志'
        return 1
    }
    clashproxy >/dev/null && _set_system_proxy
    _okcat '已开启代理环境'
}

watch_proxy() {
    [ -z "$http_proxy" ] && {
        # [[ "$0" == -* ]] && { # 登录式shell
        [[ $- == *i* ]] && { # 交互式shell
            clashon
        }
    }
}

function clashoff() {
    clashstatus >&/dev/null && {
        pkill -9 -f $BIN_KERNEL >/dev/null
        clashstatus >&/dev/null && _tunstatus >&/dev/null && {
            _tunoff || _error_quit "请先关闭 Tun 模式"
        }
        pkill -9 -f $BIN_KERNEL >/dev/null
        clashstatus >&/dev/null && {
            _failcat '代理环境关闭失败'
            return 1
        }
    }
    _unset_system_proxy
    _okcat '已关闭代理环境'
}

clashrestart() {
    clashoff >/dev/null
    clashon
}

function clashproxy() {
    case "$1" in
    -h | --help)
        cat <<EOF

- 查看系统代理状态
  clashproxy

- 开启系统代理
  clashproxy on

- 关闭系统代理
  clashproxy off

EOF
        return 0
        ;;
    on)
        clashstatus >&/dev/null || {
            _failcat "$KERNEL_NAME 未运行，请先执行 clashon"
            return 1
        }
        "$BIN_YQ" -i '._custom.system-proxy.enable = true' "$CLASH_CONFIG_MIXIN"
        _set_system_proxy
        _okcat '已开启系统代理'
        ;;
    off)
        "$BIN_YQ" -i '._custom.system-proxy.enable = false' "$CLASH_CONFIG_MIXIN"
        _unset_system_proxy
        _okcat '已关闭系统代理'
        ;;
    *)
        local system_proxy_enable=$("$BIN_YQ" '._custom.system-proxy.enable' "$CLASH_CONFIG_MIXIN" 2>/dev/null)
        case $system_proxy_enable in
        true)
            _okcat "系统代理：开启
$(env | grep -i 'proxy=')"
            ;;
        *)
            _failcat "系统代理：关闭"
            ;;
        esac
        ;;
    esac
}

function clashstatus() {
    pgrep -fa $BIN_KERNEL "$@"
    pgrep -fa $BIN_KERNEL >&/dev/null
}

function clashlog() {
    less < ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log "$@"
}

function clashui() {
    _detect_ext_addr
    clashstatus >&/dev/null || clashon >/dev/null
    local query_url='api64.ipify.org' # ifconfig.me
    local public_ip=$(curl -s --noproxy "*" --location --max-time 2 $query_url)
    local public_address="http://${public_ip:-公网}:${EXT_PORT}/ui"

    local local_ip=$EXT_IP
    local local_address="http://${local_ip}:${EXT_PORT}/ui"
    printf "\n"
    printf "╔═══════════════════════════════════════════════╗\n"
    printf "║                %s                  ║\n" "$(_okcat 'Web 控制台')"
    printf "║═══════════════════════════════════════════════║\n"
    printf "║                                               ║\n"
    printf "║     🔓 注意放行端口：%-5s                    ║\n" "$EXT_PORT"
    printf "║     🏠 内网：%-31s  ║\n" "$local_address"
    printf "║     🌏 公网：%-31s  ║\n" "$public_address"
    printf "║     ☁️  公共：%-31s  ║\n" "$URL_CLASH_UI"
    printf "║                                               ║\n"
    printf "╚═══════════════════════════════════════════════╝\n"
    printf "\n"
}

_merge_config() {
    cat "$CLASH_CONFIG_RUNTIME" >"$CLASH_CONFIG_TEMP" 2>/dev/null
    # shellcheck disable=SC2016
    "$BIN_YQ" eval-all '
      ########################################
      #              Load Files              #
      ########################################
      select(fileIndex==0) as $config |
      select(fileIndex==1) as $mixin |
      
      ########################################
      #              Deep Merge              #
      ########################################
      $mixin |= del(._custom) |
      (($config // {}) * $mixin) as $runtime |
      $runtime |
      
      ########################################
      #               Rules                  #
      ########################################
      .rules = (
        ($mixin.rules.prefix // []) +
        ($config.rules // []) +
        ($mixin.rules.suffix // [])
      ) |
      
      ########################################
      #                Proxies               #
      ########################################
      .proxies = (
        ($mixin.proxies.prefix // []) +
        (
          ($config.proxies // []) as $configList |
          ($mixin.proxies.override // []) as $overrideList |
          $configList | map(
            . as $configItem |
            (
              $overrideList[] | select(.name == $configItem.name)
            ) // $configItem
          )
        ) +
        ($mixin.proxies.suffix // [])
      ) |
      
      ########################################
      #             ProxyGroups              #
      ########################################
      .proxy-groups = (
        ($mixin.proxy-groups.prefix // []) +
        (
          ($config.proxy-groups // []) as $configList |
          ($mixin.proxy-groups.override // []) as $overrideList |
          $configList | map(
            . as $configItem |
            (
              $overrideList[] | select(.name == $configItem.name)
            ) // $configItem
          )
        ) +
        ($mixin.proxy-groups.suffix // [])
      ) |

      ########################################
      #         ProxyGroups Inject           #
      # 把 inject 表里的 proxy 名追加到对应   #
      # 已有 group 的 .proxies 列表（自动去重）#
      # 用途：把自定义 / 链式代理无侵入地     #
      # 插入到订阅自带的节点组里，避免        #
      # override 整组的麻烦                  #
      ########################################
      ($mixin.proxy-groups.inject // {}) as $inj |
      .proxy-groups[] |= (
        . as $g |
        ($inj | .[$g.name] // []) as $extra |
        .proxies = (.proxies + $extra | unique)
      )
    ' "$CLASH_CONFIG_BASE" "$CLASH_CONFIG_MIXIN" >"$CLASH_CONFIG_RUNTIME"
    _valid_config "$CLASH_CONFIG_RUNTIME" || {
        cat "$CLASH_CONFIG_TEMP" >"$CLASH_CONFIG_RUNTIME"
        _error_quit "验证失败：请检查 Mixin 配置"
    }
}

_merge_config_restart() {
    _merge_config
    pkill -9 -f $BIN_KERNEL >/dev/null
    clashstatus >&/dev/null && _tunstatus >&/dev/null && {
        _tunoff || _error_quit "请先关闭 Tun 模式"
    }
    pkill -9 -f $BIN_KERNEL >/dev/null
    sleep 0.1
    ( nohup $BIN_KERNEL -d $CLASH_RESOURCES_DIR -f $CLASH_CONFIG_RUNTIME > ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log 2>&1 & ) >/dev/null
    sleep 0.1
}
_get_secret() {
    "$BIN_YQ" '.secret // ""' "$CLASH_CONFIG_RUNTIME"
}
function clashsecret() {
    case "$1" in
    -h | --help)
        cat <<EOF

- 查看 Web 密钥
  clashsecret

- 修改 Web 密钥
  clashsecret <new_secret>

EOF
        return 0
        ;;
    esac

    case $# in
    0)
        _okcat "当前密钥：$(_get_secret)"
        ;;
    1)
        "$BIN_YQ" -i ".secret = \"$1\"" "$CLASH_CONFIG_MIXIN" || {
            _failcat "密钥更新失败，请重新输入"
            return 1
        }
        _merge_config_restart
        _okcat "密钥更新成功，已重启生效"
        ;;
    *)
        _failcat "密钥不要包含空格或使用引号包围"
        ;;
    esac
}

_tunstatus() {
    local tun_status=$("$BIN_YQ" '.tun.enable' "${CLASH_CONFIG_RUNTIME}")
    case $tun_status in
    true)
        _okcat 'Tun 状态：启用'
        ;;
    *)
        _failcat 'Tun 状态：关闭'
        ;;
    esac
}
_tunoff() {
    _tunstatus >/dev/null || return 0
    sudo pkill -9 -f $BIN_KERNEL
    # 强制恢复终端输出处理
    stty opost 2>/dev/null
    clashstatus >&/dev/null || {
        "$BIN_YQ" -i '.tun.enable = false' "$CLASH_CONFIG_MIXIN"
        _merge_config
        clashon >/dev/null
        _okcat "Tun 模式已关闭"
        return 0
    }
    _tunstatus >&/dev/null && _failcat "Tun 模式关闭失败"
}
_sudo_restart() {
    sudo pkill -9 -f $BIN_KERNEL
    sudo sh -c "nohup $BIN_KERNEL -d $CLASH_RESOURCES_DIR -f $CLASH_CONFIG_RUNTIME < /dev/null > ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log 2>&1 &"
    sleep 0.5
    # 强制恢复终端输出处理
    stty opost 2>/dev/null
}
_tunon() {
    _tunstatus 2>/dev/null && return 0
    sudo pkill -9 -f $BIN_KERNEL
    "$BIN_YQ" -i '.tun.enable = true' "$CLASH_CONFIG_MIXIN"
    _merge_config
    sudo sh -c "nohup $BIN_KERNEL -d $CLASH_RESOURCES_DIR -f $CLASH_CONFIG_RUNTIME < /dev/null > ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log 2>&1 &"
    sleep 0.5
    # 强制恢复终端输出处理
    stty opost 2>/dev/null

    clashstatus >&/dev/null || _error_quit "Tun 模式开启失败"
    local fail_msg="Start TUN listening error|unsupported kernel version"
    local ok_msg="Tun adapter listening at|TUN listening iface"
    clashlog | grep -E -m1 -qs "$fail_msg" && {
        [ "$KERNEL_NAME" = 'mihomo' ] && {
            "$BIN_YQ" -i '.tun.auto-redirect = false' "$CLASH_CONFIG_MIXIN"
            _merge_config
            _sudo_restart
        }
        clashlog | grep -E -m1 -qs "$ok_msg" || {
            clashlog | grep -E -m1 "$fail_msg"
            _tunoff >&/dev/null
            _error_quit '系统内核版本不支持 Tun 模式'
        }
    }
    _okcat "Tun 模式已开启"
}

function clashtun() {
    case "$1" in
    -h | --help)
        cat <<EOF

- 查看 Tun 状态
  clashtun

- 开启 Tun 模式
  clashtun on

- 关闭 Tun 模式
  clashtun off
  
EOF
        return 0
        ;;
    on)
        _tunon
        ;;
    off)
        _tunoff
        ;;
    *)
        _tunstatus
        ;;
    esac
}

function clashmixin() {
    case "$1" in
    -h | --help)
        cat <<EOF

- 查看 Mixin 配置：$CLASH_CONFIG_MIXIN
  clashmixin

- 编辑 Mixin 配置
  clashmixin -e

- 查看原始订阅配置：$CLASH_CONFIG_BASE
  clashmixin -c

- 查看运行时配置：$CLASH_CONFIG_RUNTIME
  clashmixin -r

EOF
        return 0
        ;;
    -e)
        vim "$CLASH_CONFIG_MIXIN" && {
            _merge_config_restart && _okcat "配置更新成功，已重启生效"
        }
        ;;
    -r)
        less "$CLASH_CONFIG_RUNTIME"
        ;;
    -c)
        less "$CLASH_CONFIG_BASE"
        ;;
    *)
        less "$CLASH_CONFIG_MIXIN"
        ;;
    esac
}

function clashupgrade() {
    for arg in "$@"; do
        case $arg in
        -h | --help)
            cat <<EOF
Usage:
  clashupgrade [OPTIONS]

Options:
  -v, --verbose       输出内核升级日志
  -r, --release       升级至稳定版
  -a, --alpha         升级至测试版
  -h, --help          显示帮助信息

EOF
            return 0
            ;;
        -v | --verbose)
            local log_flag=true
            ;;
        -r | --release)
            channel="release"
            ;;
        -a | --alpha)
            channel="alpha"
            ;;
        *)
            channel=""
            ;;
        esac
    done

    _detect_ext_addr
    clashstatus >&/dev/null || clashon >/dev/null
    _okcat '⏳' "请求内核升级..."
    [ "$log_flag" = true ] && {
        log_cmd=(tail -f -n 0 ${CLASH_RESOURCES_DIR}/${KERNEL_NAME}.log)
        ("${log_cmd[@]}" &)

    }
    local res=$(
        curl -X POST \
            --silent \
            --noproxy "*" \
            --location \
            -H "Authorization: Bearer $(_get_secret)" \
            "http://${EXT_IP}:${EXT_PORT}/upgrade?channel=$channel"
    )
    [ "$log_flag" = true ] && pkill -9 -f "${log_cmd[*]}"

    grep '"status":"ok"' <<<"$res" && {
        _okcat "内核升级成功"
        return 0
    }
    grep 'already using latest version' <<<"$res" && {
        _okcat "已是最新版本"
        return 0
    }
    _failcat "内核升级失败，请检查网络或稍后重试"
}

function clashsub() {
    case "$1" in
    add)
        shift
        _sub_add "$@"
        ;;
    del)
        shift
        _sub_del "$@"
        ;;
    list | ls | '')
        shift
        _sub_list "$@"
        ;;
    use)
        shift
        _sub_use "$@"
        ;;
    update)
        shift
        _sub_update "$@"
        ;;
    log)
        shift
        _sub_log "$@"
        ;;
    -h | --help | *)
        cat <<EOF
clashsub - Clash 订阅管理工具

Usage: 
  clashsub COMMAND [OPTIONS]

Commands:
  add <url>       添加订阅
  ls              查看订阅
  del <id>        删除订阅
  use <id>        使用订阅
  update [id]     更新订阅
  log             订阅日志

Options:
  update:
    --auto        配置自动更新
    --convert     使用订阅转换
EOF
        ;;
    esac
}
_sub_add() {
    local url=$1
    [ -z "$url" ] && {
        echo -n "$(_okcat '✈️ ' '请输入要添加的订阅链接：')"
        read -r url
        [ -z "$url" ] && _error_quit "订阅链接不能为空"
    }
    _get_url_by_id "$id" >/dev/null && _error_quit "该订阅链接已存在"

    _download_config "$CLASH_CONFIG_TEMP" "$url"
    _valid_config "$CLASH_CONFIG_TEMP" || _error_quit "订阅无效，请检查：
    原始订阅：${CLASH_CONFIG_TEMP}.raw
    转换订阅：$CLASH_CONFIG_TEMP
    转换日志：$BIN_SUBCONVERTER_LOG"

    local id=$("$BIN_YQ" '.profiles // [] | (map(.id) | max) // 0 | . + 1' "$CLASH_PROFILES_META")
    local profile_path="${CLASH_PROFILES_DIR}/${id}.yaml"
    mv "$CLASH_CONFIG_TEMP" "$profile_path"

    "$BIN_YQ" -i "
         .profiles = (.profiles // []) + 
         [{
           \"id\": $id,
           \"path\": \"$profile_path\",
           \"url\": \"$url\"
         }]
    " "$CLASH_PROFILES_META"
    _logging_sub "➕ 已添加订阅：[$id] $url"
    _okcat '🎉' "订阅已添加：[$id] $url"
}
_sub_del() {
    local id=$1
    [ -z "$id" ] && {
        echo -n "$(_okcat '✈️ ' '请输入要删除的订阅 id：')"
        read -r id
        [ -z "$id" ] && _error_quit "订阅 id 不能为空"
    }
    local profile_path url
    profile_path=$(_get_path_by_id "$id") || _error_quit "订阅 id 不存在，请检查"
    url=$(_get_url_by_id "$id")
    use=$("$BIN_YQ" '.use // ""' "$CLASH_PROFILES_META")
    [ "$use" = "$id" ] && _error_quit "删除失败：订阅 $id 正在使用中，请先切换订阅"
    /usr/bin/rm -f "$profile_path"
    "$BIN_YQ" -i "del(.profiles[] | select(.id == \"$id\"))" "$CLASH_PROFILES_META"
    _logging_sub "➖ 已删除订阅：[$id] $url"
    _okcat '🎉' "订阅已删除：[$id] $url"
}
_sub_list() {
    "$BIN_YQ" "$CLASH_PROFILES_META"
}
_sub_use() {
    "$BIN_YQ" -e '.profiles // [] | length == 0' "$CLASH_PROFILES_META" >&/dev/null &&
        _error_quit "当前无可用订阅，请先添加订阅"
    local id=$1
    [ -z "$id" ] && {
        clashsub ls
        echo -n "$(_okcat '✈️ ' '请输入要使用的订阅 id：')"
        read -r id
        [ -z "$id" ] && _error_quit "订阅 id 不能为空"
    }
    local profile_path url
    profile_path=$(_get_path_by_id "$id") || _error_quit "订阅 id 不存在，请检查"
    url=$(_get_url_by_id "$id")
    cat "$profile_path" >"$CLASH_CONFIG_BASE"
    _merge_config_restart
    "$BIN_YQ" -i ".use = $id" "$CLASH_PROFILES_META"
    _logging_sub "🔥 订阅已切换为：[$id] $url"
    _okcat '🔥' '订阅已生效'
}
_get_path_by_id() {
    "$BIN_YQ" -e ".profiles[] | select(.id == \"$1\") | .path" "$CLASH_PROFILES_META" 2>/dev/null
}
_get_url_by_id() {
    "$BIN_YQ" -e ".profiles[] | select(.id == \"$1\") | .url" "$CLASH_PROFILES_META" 2>/dev/null
}
_sub_update() {
    local arg is_convert
    for arg in "$@"; do
        case $arg in
        --auto)
            command -v crontab >/dev/null || _error_quit "未检测到 crontab 命令，请先安装 cron 服务"
            crontab -l | grep -qs 'clashsub update' || {
                (
                    crontab -l 2>/dev/null
                    echo "0 0 */2 * * $SHELL -i -c 'clashsub update'"
                ) | crontab -
            }
            _okcat "已设置定时更新订阅"
            return 0
            ;;
        --convert)
            is_convert=true
            shift
            ;;
        esac
    done
    local id=$1
    [ -z "$id" ] && id=$("$BIN_YQ" '.use // 1' "$CLASH_PROFILES_META")
    local url profile_path
    url=$(_get_url_by_id "$id") || _error_quit "订阅 id 不存在，请检查"
    profile_path=$(_get_path_by_id "$id")
    _okcat "✈️ " "更新订阅：[$id] $url"

    [ "$is_convert" = true ] && {
        _download_convert_config "$CLASH_CONFIG_TEMP" "$url"
    }
    [ "$is_convert" != true ] && {
        _download_config "$CLASH_CONFIG_TEMP" "$url"
    }
    _valid_config "$CLASH_CONFIG_TEMP" || {
        _logging_sub "❌ 订阅更新失败：[$id] $url"
        _error_quit "订阅无效：请检查：
    原始订阅：${CLASH_CONFIG_TEMP}.raw
    转换订阅：$CLASH_CONFIG_TEMP
    转换日志：$BIN_SUBCONVERTER_LOG"
    }
    _logging_sub "✅ 订阅更新成功：[$id] $url"
    cat "$CLASH_CONFIG_TEMP" >"$profile_path"
    use=$("$BIN_YQ" '.use // ""' "$CLASH_PROFILES_META")
    [ "$use" = "$id" ] && clashsub use "$use" && return
    _okcat '订阅已更新'
}
_logging_sub() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >>"${CLASH_PROFILES_LOG}"
}
_sub_log() {
    tail <"${CLASH_PROFILES_LOG}" "$@"
}

########################################
#   交互选择 - 方向键 ↑ ↓ 回车确认     #
########################################
_interactive_select() {
    local items=("$@")
    local total=${#items[@]} selected=0 key key2

    printf '\e[?25l\n'
    printf '使用 ↑ ↓ 方向键移动，回车确认\n\n'

    for i in "${!items[@]}"; do
        if [ "$i" -eq "$selected" ]; then
            printf '\e[1;32m▸ %s\e[0m\n' "${items[$i]}"
        else
            printf '  %s\n' "${items[$i]}"
        fi
    done

    while true; do
        IFS= read -rsn1 key
        case "$key" in
        $'\e')
            read -rsn2 key2 2>/dev/null
            case "$key2" in
            '[A') [ "$selected" -gt 0 ] && selected=$((selected - 1)) ;;
            '[B') [ "$selected" -lt "$((total - 1))" ] && selected=$((selected + 1)) ;;
            esac
            printf '\e[%dA' "$total"
            for i in "${!items[@]}"; do
                printf '\e[2K\r'
                if [ "$i" -eq "$selected" ]; then
                    printf '\e[1;32m▸ %s\e[0m\n' "${items[$i]}"
                else
                    printf '  %s\n' "${items[$i]}"
                fi
            done
            ;;
        '')
            printf '\e[%dB\e[?25h' "$total"
            return "$selected"
            ;;
        esac
    done
}

_node_browse() {
    local group_names=() group
    while IFS= read -r group; do
        [ -z "$group" ] && continue
        group_names+=("$group")
    done <<<"$("$BIN_YQ" -r '.proxy-groups[] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)"
    [ "${#group_names[@]}" -eq 0 ] && { _failcat "未找到代理组配置"; return 1; }

    _interactive_select "${group_names[@]}"
    local gsel=$?
    local selected_group="${group_names[$gsel]}"

    local proxies
    proxies=$(_clashnode_api GET "/proxies/$(_urlencode "$selected_group")")
    [ -z "$proxies" ] && return $?

    local now_selected
    now_selected=$(echo "$proxies" | "$BIN_YQ" '.now // ""')

    local proxy_names=() name
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        [ "$name" = "$now_selected" ] && name="$name  ← 当前"
        proxy_names+=("$name")
    done <<<"$(echo "$proxies" | "$BIN_YQ" -r '.all[]' 2>/dev/null)"

    printf '\n'
    _interactive_select "${proxy_names[@]}"
    local nsel=$?
    local selected_node="${proxy_names[$nsel]%  ← 当前}"

    echo ""
    _node_select "$selected_group" "$selected_node"
}

########################################
#         clashnode - 节点管理          #
########################################
_urlencode() {
    python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

_clashnode_api() {
    local method=${1:-GET}
    local path=$2
    local data=$3
    _detect_ext_addr
    clashstatus >&/dev/null || {
        _failcat "$KERNEL_NAME 未运行，请先执行 clashon"
        return 1
    }
    if [ -n "$data" ]; then
        curl -s --noproxy "*" \
            -X "$method" \
            -H "Authorization: Bearer $(_get_secret)" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "http://${EXT_IP}:${EXT_PORT}${path}"
    else
        curl -s --noproxy "*" \
            -X "$method" \
            -H "Authorization: Bearer $(_get_secret)" \
            "http://${EXT_IP}:${EXT_PORT}${path}"
    fi
}

_node_list() {
    local proxy_groups proxy_list
    proxy_groups=$("$BIN_YQ" '.proxy-groups[] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)
    [ -z "$proxy_groups" ] && {
        _failcat "未找到代理组配置"
        return 1
    }
    printf "\n%-4s %-s\n" "序号" "代理组"
    printf "%s\n" "----------------------------------------"
    local idx=1
    while IFS= read -r group; do
        [ -z "$group" ] && continue
        printf "%-4s %-s\n" "[$idx]" "$group"
        ((idx++))
    done <<<"$proxy_groups"
    printf "\n"
}

_node_list_proxies() {
    local group=$1
    local proxies now_selected
    proxies=$(_clashnode_api GET "/proxies/$(_urlencode "$group")")
    now_selected=$(echo "$proxies" | "$BIN_YQ" '.now // ""')
    echo "$proxies" | "$BIN_YQ" -r '.all[]' 2>/dev/null | while IFS= read -r name; do
        [ -z "$name" ] && continue
        if [ "$name" = "$now_selected" ]; then
            printf "%s\t%s\n" "$name" "← 当前"
        else
            echo "$name"
        fi
    done
}

_node_test() {
    local arg url="http://www.gstatic.com/generate_204" timeout=5000
    for arg in "$@"; do
        case $arg in
        --url)
            shift
            url="$1"
            shift
            ;;
        --timeout)
            shift
            timeout="$1"
            shift
            ;;
        esac
    done

    _detect_ext_addr
    clashstatus >&/dev/null || {
        _failcat "$KERNEL_NAME 未运行，请先执行 clashon"
        return 1
    }

    _okcat '⏳' "正在测速..."
    local proxy_groups
    proxy_groups=$("$BIN_YQ" '.proxy-groups[] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)

    local idx=1 results=()
    while IFS= read -r group; do
        [ -z "$group" ] && continue
        local proxies
        proxies=$(_clashnode_api GET "/proxies/$(_urlencode "$group")" | "$BIN_YQ" -r '.all[]' 2>/dev/null)
        while IFS= read -r name; do
            [ -z "$name" ] && continue
            local latency
            latency=$(_clashnode_api GET "/proxies/$(_urlencode "$name")/delay?url=${url}&timeout=${timeout}" 2>/dev/null)
            local ms
            ms=$(echo "$latency" | "$BIN_YQ" -r '.delay // 0')
            [ "$ms" = "0" ] && ms="999999"
            results+=("$idx|$group|$name|$ms")
            ((idx++))
        done <<<"$proxies"
    done <<<"$proxy_groups"

    printf "\n%-4s %-20s %-s\n" "序号" "延迟(ms)" "节点"
    printf "%s\n" "-----------------------------------------------------------"
    local item
    # Sort by latency (ms numeric, timeout at end)
    while IFS= read -r item; do
        [ -z "$item" ] && continue
        local num group_name node_name ms
        num="${item%%|*}"
        item="${item#*|}"
        group_name="${item%%|*}"
        item="${item#*|}"
        node_name="${item%%|*}"
        ms="${item#*|}"
        printf "%-4s %-20s [%s] %s\n" "[$num]" "${ms/999999/超时}" "$group_name" "$node_name"
    done < <(printf '%s\n' "${results[@]}" | sort -t'|' -k4 -n)

    echo ""
    echo -n "$(_okcat '✈️ ' '请输入序号选择节点（直接回车退出）：')"
    read -r sel
    [ -z "$sel" ] && return 0

    local selected
    selected=$(printf '%s\n' "${results[@]}" | awk -F'|' -v s="$sel" '$1==s {print $2"|"$3}')
    [ -z "$selected" ] && {
        _failcat "无效的序号"
        return 1
    }
    local target_group target_node
    target_group="${selected%%|*}"
    target_node="${selected#*|}"
    _node_select "$target_group" "$target_node"
}

_node_select() {
    local group=$1 node=$2
    local res
    res=$(_clashnode_api PUT "/proxies/$(_urlencode "$group")" "{\"name\":\"${node}\"}")
    # API returns 204 No Content on success (empty body)
    [ -z "$res" ] && {
        _okcat "✅ 已切换：[$group] → $node"
        return 0
    }
    _failcat "切换失败：$res"
}

_node_use() {
    local group=$1
    if [ -z "$group" ]; then
        echo ""
        _node_list
        echo -n "$(_okcat '✈️ ' '请选择代理组序号：')"
        read -r sel
        [ -z "$sel" ] && return 0
        group=$("$BIN_YQ" '.proxy-groups['"$((sel - 1))"'] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)
        [ -z "$group" ] && {
            _failcat "无效的序号"
            return 1
        }
    elif [[ "$group" =~ ^[0-9]+$ ]]; then
        # resolve numeric argument to group name
        group=$("$BIN_YQ" '.proxy-groups['$(("$group" - 1))'] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)
        [ -z "$group" ] && {
            _failcat "无效的序号"
            return 1
        }
    fi

    echo ""
    _okcat "当前组：$group"
    printf "%-4s %-s\n" "序号" "节点"
    printf "%s\n" "----------------------------------------"
    local idx=1
    _node_list_proxies "$group"
    echo ""
    echo -n "$(_okcat '✈️ ' '请选择节点序号：')"
    read -r sel
    [ -z "$sel" ] && return 0

    local target_node
    target_node=$(_node_list_proxies "$group" | sed -n "${sel}p" | awk -F'\t' '{print $1}')
    [ -z "$target_node" ] && {
        _failcat "无效的序号"
        return 1
    }
    _node_select "$group" "$target_node"
}

function clashnode() {
    case "$1" in
    -h | --help)
        cat <<EOF

clashnode - 节点管理与测速

用法:
  clashnode list [序号|组名]    方向键浏览代理组+回车选节点
  clashnode test [选项]         测试所有节点延迟并选择节点
  clashnode use [序号|组名]     切换节点（交互式选择）

示例:
  clashnode                     等同于 clashnode list
  clashnode list                方向键 ↑ ↓ 浏览，回车确认
  clashnode list 1               查看序号 1 的代理组包含哪些节点
  clashnode list auto            查看 auto 组的所有节点
  clashnode test                 测试所有节点延迟（交互式选择）
  clashnode test --url https://example.com --timeout 3000
  clashnode use                  交互式选择代理组和节点
  clashnode use 1                交互式选择序号 1 代理组中的节点
  clashnode use auto             直接切换到 auto 组中的节点

方向键 / 序号说明:
  list 默认使用方向键 ↑ ↓ 浏览，回车确认选中
  list/use 均支持序号代替组名，如 clashnode list 1 查看第 1 个代理组
  test/use 执行后均会显示节点列表，输入序号即可快速切换

clashnode test 选项:
  --url <url>       指定测速 URL（默认：http://www.gstatic.com/generate_204）
  --timeout <ms>    超时毫秒（默认：5000）

EOF
        return 0
        ;;
    list)
        shift
        if [ -n "$1" ]; then
            # 支持序号或组名
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                local group
                group=$("$BIN_YQ" '.proxy-groups['$(("$1" - 1))'] | .name' "$CLASH_CONFIG_RUNTIME" 2>/dev/null)
                [ -z "$group" ] && {
                    _failcat "无效的序号"
                    return 1
                }
                set -- "$group"
            fi
            _node_list_proxies "$1"
        else
            _node_browse
        fi
        ;;
    test)
        shift
        _node_test "$@"
        ;;
    use)
        shift
        _node_use "$1"
        ;;
    *)
        _node_browse
        ;;
    esac
}

function clashctl() {
    case "$1" in
    on)
        shift
        clashon
        ;;
    off)
        shift
        clashoff
        ;;
    ui)
        shift
        clashui
        ;;
    status)
        shift
        clashstatus "$@"
        ;;
    log)
        shift
        clashlog "$@"
        ;;
    proxy)
        shift
        clashproxy "$@"
        ;;
    tun)
        shift
        clashtun "$@"
        ;;
    mixin)
        shift
        clashmixin "$@"
        ;;
    secret)
        shift
        clashsecret "$@"
        ;;
    sub)
        shift
        clashsub "$@"
        ;;
    upgrade)
        shift
        clashupgrade "$@"
        ;;
    node)
        shift
        clashnode "$@"
        ;;
    *)
        (($#)) && shift
        clashhelp "$@"
        ;;
    esac
}

clashhelp() {
    cat <<EOF
    
Usage: 
  clashctl COMMAND [OPTIONS]

Commands:
  on                    开启代理
  off                   关闭代理
  proxy                 系统代理
  status                内核状态
  ui                    面板地址
  sub                   订阅管理
  log                   内核日志
  tun                   Tun 模式
  mixin                 Mixin 配置
  secret                Web 密钥
  upgrade               升级内核
  node                  节点管理

Global Options:
  -h, --help            显示帮助信息

For more help on how to use clashctl, head to https://github.com/nelvko/clash-for-linux-install
EOF
}
