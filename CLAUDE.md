# CLAUDE.md

先读 [AGENTS.md](AGENTS.md)（工作流、目录边界、代码约定）。

## 架构速览

- `install.sh` / `uninstall.sh`：入口；安装目标 `CLASHCTL_HOME=~/clashctl`
- `scripts/preflight.sh`：安装期检查、init 系统检测、RC 文件挂载
- `scripts/lib/`：公共库（common/config/convert/service）
- `scripts/cmd/`：子命令模块，`clashctl.sh` 按 `clash<子命令>` 动态分发；`node.sh` 即 clashnode
- 运行时通过内核 REST API 操作（`external-controller`），不写配置文件

## 常用命令

```bash
bash -n scripts/cmd/node.sh      # 语法检查
tests/sandbox/run.sh             # bwrap 沙盒端到端测试
```
