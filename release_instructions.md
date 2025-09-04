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
