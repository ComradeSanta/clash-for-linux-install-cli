#!/usr/bin/env bash
# 沙盒内驱动：启动 mihomo → 验证 API → clashnode 选择器端到端测试
# 由 run.sh 在 bwrap 内调用，请勿直接在宿主机运行
set -u
export HOME=/home/arch
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
YQ="$HOME/clashctl/bin/yq"
API="http://127.0.0.1:19090"

rm -f "$HOME/clashctl/resources/cache.db"
nohup "$HOME/clashctl/bin/mihomo" -d "$HOME/clashctl/resources" \
  -f "$HOME/clashctl/resources/runtime.yaml" \
  > "$HOME/clashctl/resources/mihomo.log" 2>&1 &
KP=$!
sleep 1.5

now() { curl -s --noproxy '*' --max-time 3 "$API/proxies" | GROUP='沙盒组' "$YQ" -p json '.proxies[strenv(GROUP)].now'; }
reset_a() { curl -s --noproxy '*' -X PUT -H 'Content-Type: application/json' -d '{"name":"沙盒节点A"}' "$API/proxies/%E6%B2%99%E7%9B%92%E7%BB%84" >/dev/null; }
run_keys() { printf '%b' "$1" | timeout 20 script -qec "bash -ic '$2'" /dev/null >/dev/null 2>&1; }

fails=0
check() { # $1=测试名 $2=实际值 $3=期望值
    if [ "$2" = "$3" ]; then echo "PASS $1 ($2)"; else echo "FAIL $1 (得到 $2，期望 $3)"; fails=$((fails + 1)); fi
}

echo "初始节点: $(now)（应为 沙盒节点A）"

echo "=== 1) 方向键选成员：clashnode use 沙盒组，↓↓Enter → 沙盒节点C"
run_keys '\e[B\e[B\n' 'clashnode use 沙盒组'
check 1 "$(now)" "沙盒节点C"

echo "=== 2) q 取消 → 节点不变"
run_keys 'q' 'clashnode use 沙盒组'
check 2 "$(now)" "沙盒节点C"

echo "=== 3) Esc 取消 → 节点不变"
run_keys '\e' 'clashnode use 沙盒组'
check 3 "$(now)" "沙盒节点C"

echo "=== 4) 编号回退：PICKER=number，输入 2 → 沙盒节点B"
run_keys '2\n' 'CLASHCTL_NODE_PICKER=number clashnode use 沙盒组'
check 4 "$(now)" "沙盒节点B"

echo "=== 5) 完整两级流程：clashnode use，↓Enter 选沙盒组，↓Enter 选节点B"
reset_a
run_keys '\e[B\n\e[B\n' 'clashnode use'
check 5 "$(now)" "沙盒节点B"

echo "=== 6) 选择器路由：伪终端=arrow，管道=number"
P_TTY=$(timeout 10 script -qec "bash -ic '_node_picker'" /dev/null 2>/dev/null | tr -d '\r\n')
P_PIPE=$(bash -ic '_node_picker' 2>/dev/null)
check 6 "$P_TTY/$P_PIPE" "arrow/number"

kill $KP 2>/dev/null; wait $KP 2>/dev/null
echo "=== 结束，内核已停止，失败 $fails 项"
[ $fails -eq 0 ]
