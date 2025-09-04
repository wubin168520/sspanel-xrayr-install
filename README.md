# 🚀 SSPanel UIM 节点一键对接脚本（XrayR）

本项目提供一个**极简依赖**的一键脚本，适配主流 Linux（Debian/Ubuntu/CentOS/RHEL/Rocky/AlmaLinux/openSUSE/Arch 等）。
- 自动安装最小依赖（`curl/wget`、`tar`、`unzip`）
- 自动获取与你架构匹配的 **XrayR** 最新版本
- 一键生成 **SSPanel** 对接配置并注册为系统服务（systemd 为主，非 systemd 提供 SysV 启动脚本降级）

> 说明：完全覆盖“所有系统”在实践上不可行（各发行版/Init 差异较大）。脚本尽量覆盖主流 Linux 并降低依赖。

---

## ✅ 快速开始

### 方式一：本地运行脚本
```bash
sudo bash sspanel-uim-oneclick.sh
```
按菜单选择：
1. 安装/更新 XrayR  
2. 生成/更新配置（输入 `ApiHost`、`ApiKey`、`NodeID`、节点类型）

### 方式二：从 GitHub Raw 一键执行（建库后）
把脚本提交到你的仓库后，将用户名与仓库替换成你自己的：
```bash
bash <(curl -Ls https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库>/main/sspanel-uim-oneclick.sh)
```

---

## ⚙️ 注意事项
- 使用 **root** 运行（或 `sudo`）
- 服务器需联网，可访问 GitHub Releases
- 防火墙/安全组需放行你的节点端口
- 非 systemd 环境会安装 `/etc/init.d/xrayr` 简化脚本

---

## 🧰 常见问题
- **提示缺少 curl/wget/tar/unzip？** 脚本会尝试用系统包管理器自动安装；若仍失败，请手动安装后重试。  
- **下载 XrayR 失败？** 检查网络到 `api.github.com` 与 `github.com` 的连通性，或稍后再试。  
- **如何卸载？** 进入脚本菜单选择 `卸载`，会清理程序、配置与服务。

---

## 📄 许可
脚本可自由修改与分发，适合放入你的仓库用于快速对接。

---

# 发布 Release 指南

1. **推送到 GitHub**：
   ```bash
   git init
   git add .
   git commit -m "Initial commit: SSPanel UIM 一键对接脚本"
   git branch -M main
   git remote add origin https://github.com/<你的GitHub用户名>/<你的仓库名>.git
   git push -u origin main
   ```

2. **创建 Release**：
   - 打开 GitHub 仓库页面 → `Releases` → `Create a new release`
   - 输入 Tag，例如 `v1.0.0`
   - 填写标题：`SSPanel UIM 一键对接脚本 v1.0.0`
   - 描述：
     ```
     首个版本发布，支持主流 Linux 系统，自动对接 SSPanel UIM。
     ```
   - 上传 `sspanel-uim-oneclick.sh` 文件到 Assets（可选）

3. **一键安装命令**：
   用户可直接运行：
   ```bash
   bash <(curl -Ls https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库名>/main/sspanel-uim-oneclick.sh)
   ```
