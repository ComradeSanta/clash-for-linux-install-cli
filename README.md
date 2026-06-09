<h1 align="center">
  clashctl
</h1>

<p align="center">Linux 下 mihomo / clash 一键安装与管理工具 (CLI Fork)</p>

<p align="center">
  <img alt="GitHub License" src="https://img.shields.io/github/license/ComradeSanta/clash-for-linux-install-cli" />
  <img alt="GitHub top language" src="https://img.shields.io/github/languages/top/ComradeSanta/clash-for-linux-install-cli" />
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ComradeSanta/clash-for-linux-install-cli" />
</p>

> 本仓库基于 [`nelvko/clash-for-linux-install`](https://github.com/nelvko/clash-for-linux-install) fork，修复了若干阻碍跨发行版使用的问题（详见 [Fork 修复](#-fork-修复)）。

## 🎯 适用场景

如果你的 Linux 设备没有装 GUI——服务器、NAS、嵌入式盒子、或者干脆只通过 `ssh` 连过去——本 fork 让你**不打开任何浏览器**也能完成日常代理操作：

- 终端里浏览 / 切换代理组和节点：`clashnode list`、`clashnode use`
- 终端里跑节点测速并按延迟排序：`clashnode test`
- 添加 / 切换 / 更新订阅：`clashsub add` / `use` / `update`
- 启停内核、开关系统代理、查看日志：`clashon` / `clashoff` / `clashlog` 等

只装一个内核 + 一套 `clashctl` 命令，纯 TTY 下也能用上完整的代理功能。

## 📸 Preview

![preview](resources/preview.png)

## ✨ Features

- 一键安装：部署 `mihomo` / `clash` 内核、Web 面板及配套组件。
- 环境兼容：支持 `root` 与普通用户，适配主流 `Linux` 发行版（Debian / Ubuntu / Arch / Alpine 等）和容器环境。
- 服务管理：适配 `systemd`、`OpenRC`、`runit`、`SysVinit`，无服务管理器时使用 `nohup` 运行。
- 命令管理：通过 `clashctl` 管理代理内核的启停、状态、日志、订阅、Web 密钥和内核升级。
- 订阅维护：支持订阅添加、切换、更新、自动更新、订阅转换。
- 配置扩展：支持 `Mixin` 合并、`Tun` 模式、端口冲突检测和运行时配置校验。

## 🚀 Installation

在终端中执行以下命令即可完成安装：

```bash
git clone --branch master --depth 1 https://github.com/ComradeSanta/clash-for-linux-install-cli.git \
  && cd clash-for-linux-install-cli \
  && bash install.sh
```

也可以直接指定内核与订阅链接：

```bash
bash install.sh mihomo "https://your-subscription-url"
```

- 国内网络环境下可在 `git clone` 前加 `https://gh-proxy.org/` 等[加速前缀](https://ghproxy.link/)。
- 可通过 `.env` 文件自定义安装选项（内核版本、安装路径、Web UI 等）。

## 🧭 命令一览

安装完成后，shell 中会暴露以下命令（`clashctl` 是顶层入口，其余是其子命令的便捷别名）：

| 命令 | 作用 |
| --- | --- |
| `clashon` | 启动内核 |
| `clashoff` | 停止内核 |
| `clashrestart` | 重启内核 |
| `clashstatus` | 查看内核运行状态 |
| `clashlog` | 查看内核实时日志 |
| `clashui` | 打印 Web 面板地址 |
| `clashsecret` | 查看 / 重置 Web 鉴权密钥 |
| `clashtun [on\|off]` | 开关 Tun 模式（需 `sudo`） |
| `clashproxy [on\|off]` | 开关系统代理 |
| `clashmixin [-e\|-r\|-c]` | 查看 / 编辑 Mixin、运行时、原始订阅配置 |
| `clashsub <cmd>` | 订阅管理（见下） |
| `clashnode <cmd>` | 节点管理与测速（见下） |
| `clashupgrade` | 一键升级内核 |
| `clashhelp` | 打印顶层帮助 |

任何子命令后接 `-h` 或 `--help` 都能查看详细用法，例如 `clashnode -h`、`clashsub -h`、`clashtun -h`。

### 订阅管理 `clashsub`

```bash
clashsub add <url>           # 添加订阅
clashsub ls                  # 列出所有订阅（含 id、是否启用）
clashsub use <id>            # 切换到指定订阅
clashsub del <id>            # 删除订阅
clashsub update [id]         # 重新下载订阅；id 省略则全部更新
clashsub update --auto       # 注册 crontab，每 2 天自动更新
clashsub log                 # 查看订阅相关日志
```

### 节点管理与测速 `clashnode`

`clashnode` 通过 mihomo 的 `/proxies/{name}/delay` 接口测速，并把节点切换写入运行时配置，不修改任何 YAML 文件。

```bash
clashnode                    # 方向键浏览代理组（等同 clashnode list）
clashnode list               # 交互式浏览所有代理组
clashnode list 1             # 查看序号 1 代理组下所有节点
clashnode list auto          # 查看名为 auto 的组下所有节点
clashnode test               # 测速所有节点并按延迟排序（交互式选择）
clashnode test --url <url> --timeout 3000   # 自定义测速 URL 与超时（ms）
clashnode use                # 交互式选择代理组 + 节点
clashnode use 1              # 在序号 1 代理组里交互式挑节点
clashnode use auto           # 在 auto 组里交互式挑节点
```

> `clashnode list` 默认方向键 `↑` `↓` 浏览，回车确认；序号 `1` 可与组名 `auto` 互换使用。
> `clashnode test` 默认测速 URL 是 `http://www.gstatic.com/generate_204`，超时 5000ms。
> 上游版本此处长期处于"全 999999"状态，因为调用了 mihomo 不存在的端点。本 fork 已修复（见 [Fork 修复](#-fork-修复)）。

## 🛠 Fork 修复

相对上游主要改动：

- **去除硬编码路径**：`scripts/cmd/clashctl.sh` 中残留的 `/home/pi/clashctl/...` 路径全部替换为 `$BIN_KERNEL`、`$CLASH_RESOURCES_DIR`、`$CLASH_CONFIG_RUNTIME` 等变量，使脚本在 `~/clashctl` 或自定义 `CLASH_BASE_DIR` 下都能正常工作。
- **修复 `clashnode test`**：上游调用的 `/proxy/verify` 在 mihomo 中并不存在（始终返回 404），改为正确的 `/proxies/{name}/delay` 端点，并解析 `.delay` 字段。现在 `clashnode test` 能返回真实延迟而不是清一色 `999999`。
- **修复 URL 编码注入隐患**：节点名包含 `'` / 反引号 / `$()` 时，旧代码会把字符串直接拼进 `python3 -c "..."` 造成命令注入或语法错误。新版本统一走 `_urlencode` 辅助函数，通过 `argv` 传参，完全避免 shell 字符串插值。

## 📖 Documentation

命令用法与上游一致，可参考上游 wiki：

- [Usage](https://github.com/nelvko/clash-for-linux-install/wiki) — 命令用法与示例。
- [FAQ](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ) — 常见问题。

## ⭐ Star History

<a href="https://www.star-history.com/#ComradeSanta/clash-for-linux-install-cli&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=ComradeSanta/clash-for-linux-install-cli&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=ComradeSanta/clash-for-linux-install-cli&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=ComradeSanta/clash-for-linux-install-cli&type=Date" />
 </picture>
</a>

## 🙏 Credits

- 上游项目：[`nelvko/clash-for-linux-install`](https://github.com/nelvko/clash-for-linux-install)
- 代理内核：[`MetaCubeX/mihomo`](https://github.com/MetaCubeX/mihomo)

## ⚠️ Disclaimer

- 编写本项目主要目的为学习和研究 `Shell` 编程，不得将本项目中任何内容用于违反国家/地区/组织等的法律法规或相关规定的其他用途。
- 本项目保留随时对免责声明进行补充或更改的权利，直接或间接使用本项目内容的个人或组织，视为接受本项目的特别声明。
