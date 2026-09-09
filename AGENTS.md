# AGENTS.md

本仓库是 [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) 的个人 fork（上游 remote 名为 `upstream`）。

## fork 相对上游的定制点

- `README.md`：自有徽章、命令表、Credits；不含上游广告位与 Star History
- 无 `.github/` 目录（有意删除，上游同步时保留删除）
- `scripts/cmd/node.sh`：方向键节点选择器（`_node_arrow_select` / `_node_picker`），交互终端默认方向键；`CLASHCTL_NODE_PICKER=fzf|arrow|number` 可切换
- `install.sh`：保留 clashtun 重启与 clashnode 快速上手提示

## 开发工作流（必须遵守）

1. **改代码一律开分支**：`git checkout -b feat/xxx`，不直接在 master 上改
2. **提交前**：`bash -n` 检查所有改动的 `.sh`
3. **测试**：用 bwrap 沙盒做端到端验证，不许直接在现役安装上试
   ```bash
   tests/sandbox/run.sh   # 首次自动搭建，之后增量同步脚本并重跑
   ```
4. **合并推送**：测试通过后 `git checkout master && git merge --no-ff feat/xxx && git push`
5. **部署由用户决定时机**：`bash install.sh` 重装到 `~/clashctl` 会重启代理，执行前必须先问用户
6. **上游同步**：`git fetch upstream && git merge upstream/master && git push`；
   冲突预期出现在 `README.md`（保留本 fork 版）和 `.github/`（保留删除）

## 目录边界

- 本仓库 = 唯一源码，所有改动都在这里做
- `~/clashctl` = install.sh 的安装目标（`CLASHCTL_HOME`），是运行中的现役实例。
  **不要直接改它的脚本**——改了会被下次重装覆盖，且不会进入版本管理
- 历史版本归档在 `~/projects/archived/clash-history-*.tar.gz`，只读参考

## 代码约定

- bash，公共函数进 `scripts/lib/`，子命令进 `scripts/cmd/`
- 交互菜单输出到 stderr，结果值输出到 stdout（可被 `$()` 捕获）
- 选择结果经变量/数组返回，**禁止用 return 码传数据**（上限 255）
- 隐藏光标（`\e[?25l`）后必须保证所有退出路径恢复（`\e[?25h`），含 Ctrl-C（trap INT）
- curl 一律带 `--noproxy '*'`，避免请求走代理回环
