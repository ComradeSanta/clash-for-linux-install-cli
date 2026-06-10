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

## 🎯 新增

原本依赖浏览器打开webui才可以选择节点，对于还没有装GUI的设备不太友好，如果你的 Linux 设备没有装 GUI——服务器、NAS、嵌入式盒子、或者只通过 `ssh` 连接。现在这个版本可以让你**不打开任何浏览器**也能完成基础代理操作：

- 终端里浏览 / 切换代理组和节点：`clashnode'/`clashnode list`
<img width="472" height="421" alt="Screenshot From 2026-06-10 00-57-40" src="https://github.com/user-attachments/assets/e9352401-cca4-4efd-97cb-4979e87defd5" />

<img width="472" height="421" alt="Screenshot From 2026-06-10 00-58-12" src="https://github.com/user-attachments/assets/86f08eea-f31e-434d-b781-c1be36bb1eb1" />


- 终端里跑节点测速并按延迟排序：`clashnode test`
- 增强模式/Tun模式：'clashtun on' 'clashtun off，或者'/'clashctl tun on'/'clashctl tun off。
- 命令行不开Tun模式可能无法正常连接，建议把Tun模式重新关了再开一下


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
git clone https://github.com/ComradeSanta/clash-for-linux-install-cli.git \
  && cd clash-for-linux-install-cli \
  && bash install.sh
```

- 国内网络环境下可在 `git clone` 前加 `https://gh-proxy.org/` 等[加速前缀](https://ghproxy.link/)。
```bash
git clone https://gh-proxy.org/github.com/ComradeSanta/clash-for-linux-install-cli.git \
  && cd clash-for-linux-install-cli \
  && bash install.sh
```
- 可通过 `.env` 文件自定义安装选项（内核版本、安装路径、Web UI 等）。

## 🧭 使用与命令

安装完整后会提示粘贴url，按提示把订阅的url粘贴进去并且按回车
执行 `clashnode` 选择节点
命令行环境

| 命令 | 作用 |
| --- | --- |
| `clashon` | 启动内核 |
| `clashoff` | 停止内核 |
| `clashrestart` | 重启内核 |
| `clashstatus` | 查看内核运行状态 |
| `clashlog` | 查看内核实时日志 |
| `clashui` | 打印 Web 面板地址 |
| `clashsecret` | 查看 / 重置 Web 鉴权密钥 |
| `clashtun [on\|off]` | 开关 Tun 模式 |
| `clashproxy [on\|off]` | 开关系统代理 |
| `clashmixin [-e\|-r\|-c]` | 查看 / 编辑 Mixin、运行时、原始订阅配置 |
| `clashsub <cmd>` | 订阅管理（见下） |
| `clashnode <cmd>` | 节点管理与测速（见下） |
| `clashupgrade` | 一键升级内核 |
| `clashhelp` | 打印顶层帮助 |

任何子命令后接 `-h` 或 `--help` 都能查看详细用法，例如 `clashnode -h`、`clashsub -h`、`clashtun -h`。


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
