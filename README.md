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

- 终端里浏览 / 切换代理组和节点：`clashnode'/`clashnode list`
<img width="472" height="421" alt="Screenshot From 2026-06-10 00-58-12" src="https://github.com/user-attachments/assets/86f08eea-f31e-434d-b781-c1be36bb1eb1" />
<img width="472" height="421" alt="Screenshot From 2026-06-10 00-57-40" src="https://github.com/user-attachments/assets/e9352401-cca4-4efd-97cb-4979e87defd5" />

- 终端里跑节点测速并按延迟排序：`clashnode test`
- 启停内核、开关系统代理、查看日志：`clashon` / `clashoff` /
- 增强模式/Tun模式：‘clashtun on'/'clashtun off'/
- 命令行不开Tun模式可能无法正常连接，也可能显示Tun模式开了但是不能正常连接，建议把Tun模式重新关了再开一下


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
