#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# SSPanel UIM 节点一键对接脚本（XrayR 后端）
# v3：增强下载文件识别（兼容 .zip/.ZIP/.tar.gz/.tgz 以及双扩展 .zip.ZIP）
# -----------------------------------------------------------------------------
set -euo pipefail

XRAYR_REPO="XrayR-project/XrayR"
PREFIX="/usr/local"
XRAYR_DIR="$PREFIX/XrayR"
CONF_DIR="/etc/XrayR"
SERVICE_NAME="xrayr"
DOWNLOAD_TMP="/tmp/xrayr_download"

c_red()   { echo -e "\033[31m$*\033[0m"; }
c_green() { echo -e "\033[32m$*\033[0m"; }
c_yellow(){ echo -e "\033[33m$*\033[0m"; }

need_root() { if [ "${EUID:-$(id -u)}" -ne 0 ]; then c_red "请使用 root 权限运行：sudo bash $0"; exit 1; fi; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

PM=""
choose_pm() {
  if has_cmd apt-get; then PM=apt-get
  elif has_cmd dnf; then PM=dnf
  elif has_cmd yum; then PM=yum
  elif has_cmd pacman; then PM=pacman
  elif has_cmd zypper; then PM=zypper
  elif has_cmd apk; then PM=apk
  else PM=""; c_yellow "未识别包管理器，可能需要你手动安装 curl/tar/unzip"; fi
}

install_basics() {
  local pkgs=(curl wget tar unzip)
  for p in "${pkgs[@]}"; do
    if ! has_cmd "$p"; then
      c_yellow "安装依赖：$p"
      case "$PM" in
        apt-get) apt-get update -y && apt-get install -y "$p" ;;
        dnf) dnf install -y "$p" ;;
        yum) yum install -y "$p" ;;
        pacman) pacman -Sy --noconfirm "$p" ;;
        zypper) zypper --non-interactive install "$p" ;;
        apk) apk add --no-cache "$p" ;;
        *) c_yellow "请手动安装 $p";;
      esac
    fi
  done
}

arch_map() {
  case "$(uname -m)" in
    x86_64|amd64) echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    armv7l|armv7) echo armv7 ;;
    armv6l|armv6) echo armv6 ;;
    mips64) echo mips64 ;;
    mips64le) echo mips64le ;;
    s390x) echo s390x ;;
    *) echo amd64 ;;
  esac
}

fetch_latest() {
  mkdir -p "$DOWNLOAD_TMP"
  rm -f "$DOWNLOAD_TMP"/* 2>/dev/null || true
  local arch; arch=$(arch_map)
  c_green "检测到架构: $arch"
  c_green "正在查询最新版本……"

  local api="https://api.github.com/repos/${XRAYR_REPO}/releases/latest"
  local meta url file
  if has_cmd curl; then meta=$(curl -fsSL "$api") || true; else meta=$(wget -qO- "$api") || true; fi
  [ -z "$meta" ] && { c_red "获取版本信息失败"; exit 1; }

  url=$(echo "$meta" | grep -Eo '"browser_download_url":\s*"[^"]+"' | cut -d '"' -f4 | grep -iE "linux.*(${arch}|64)\.(zip|tar\.gz)$" | head -n1) || true
  [ -z "$url" ] && { c_red "未找到匹配架构的下载地址"; exit 1; }

  file="$DOWNLOAD_TMP/$(basename "$url")"
  c_green "将下载: $url"
  if has_cmd curl; then curl -fL "$url" -o "$file"; else wget -O "$file" "$url"; fi

  # 兜底：如果服务端强制了 Content-Disposition 导致文件名不同，则取下载目录里最新文件
  if [ ! -f "$file" ]; then
    file="$(ls -1t "$DOWNLOAD_TMP" 2>/dev/null | head -n1)"
    file="$DOWNLOAD_TMP/$file"
  fi
  c_green "保存到: $file"

  echo "$file"
}

install_xrayr() {
  local pkg="$1"
  mkdir -p "$XRAYR_DIR" "$CONF_DIR"

  # 再次兜底：如果传入路径不存在，挑选下载目录最新文件
  if [ ! -f "$pkg" ]; then
    pkg="$(ls -1t "$DOWNLOAD_TMP"/* 2>/dev/null | head -n1)"
  fi
  [ -z "${pkg:-}" ] && { c_red "未找到已下载的安装包"; exit 1; }

  local lower="${pkg,,}"  # 转为小写以便匹配
  case "$lower" in
    *.zip|*.zip.zip) unzip -o "$pkg" -d "$XRAYR_DIR" >/dev/null ;;
    *.tar.gz|*.tgz)  tar -zxvf "$pkg" -C "$XRAYR_DIR" >/dev/null ;;
    *) c_yellow "未知压缩格式（$pkg），尝试解压……"
       unzip -o "$pkg" -d "$XRAYR_DIR" >/dev/null 2>&1 || tar -zxvf "$pkg" -C "$XRAYR_DIR" >/dev/null 2>&1 || { c_red "解压失败"; exit 1; } ;;
  esac

  if [ ! -x "$XRAYR_DIR/XrayR" ] && [ -x "$XRAYR_DIR/xrayr" ]; then mv -f "$XRAYR_DIR/xrayr" "$XRAYR_DIR/XrayR"; fi
  chmod +x "$XRAYR_DIR/XrayR" || true
  ln -sf "$XRAYR_DIR/XrayR" /usr/local/bin/XrayR

  if ! id -u xrayr >/dev/null 2>&1; then useradd -r -s /sbin/nologin xrayr || useradd -r xrayr || true; fi
  chown -R xrayr:xrayr "$XRAYR_DIR" "$CONF_DIR" || true
}

make_config() {
  local conf="$CONF_DIR/config.yml"
  c_green "\n开始生成配置文件（SSPanel）"
  read -rp "SSPanel 站点地址(例如 https://panel.example.com): " api_host
  read -rp "SSPanel Api Key: " api_key
  read -rp "节点 ID (NodeID): " node_id
  read -rp "节点类型 [V2ray/Trojan/SS] (默认 V2ray): " node_type
  node_type=${node_type:-V2ray}

  cat > "$conf" <<EOF
Log:
  Level: info
  AccessPath: ''
  ErrorPath: ''
DnsConfigPath: ''
RoutingConfigPath: ''
OutboundConfigPath: ''
Nodes:
  - PanelType: "SSpanel"
    ApiConfig:
      ApiHost: "$api_host"
      ApiKey: "$api_key"
      NodeID: $node_id
      NodeType: "$node_type"
      Timeout: 30
      EnableVless: false
      RuleListPath: ''
    ControllerConfig:
      ListenIP: 0.0.0.0
      UpdatePeriodic: 60
      EnableDNS: false
      DisableFallback: false
      CertConfig:
        CertMode: none
        CertDomain: ''
        CertFile: ''
        KeyFile: ''
        Provider: ''
        Email: ''
        DNSEnv: {}
EOF
  chown -R xrayr:xrayr "$CONF_DIR"
  c_green "配置已写入: $conf"
}

install_service() {
  if has_cmd systemctl; then
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=XrayR Service
After=network.target

[Service]
Type=simple
User=xrayr
Group=xrayr
WorkingDirectory=$XRAYR_DIR
ExecStart=$XRAYR_DIR/XrayR -config $CONF_DIR/config.yml
Restart=on-failure
RestartSec=5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now "$SERVICE_NAME"
    c_green "已启动并设置开机自启：systemctl status ${SERVICE_NAME}"
  else
    cat > "/etc/init.d/${SERVICE_NAME}" <<'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          xrayr
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: XrayR Service
### END INIT INFO

DAEMON="/usr/local/XrayR/XrayR"
CONF="/etc/XrayR/config.yml"
PIDFILE="/var/run/xrayr.pid"

start() { echo "Starting XrayR..."; start-stop-daemon --start --background --make-pidfile --pidfile $PIDFILE --exec $DAEMON -- -config $CONF; }
stop()  { echo "Stopping XrayR..."; start-stop-daemon --stop --pidfile $PIDFILE --retry 5 || true; }
status(){ if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; then echo "XrayR running (pid $(cat $PIDFILE))"; else echo "XrayR not running"; fi; }
case "$1" in start) start;; stop) stop;; restart) stop; sleep 1; start;; status) status;; *) echo "Usage: /etc/init.d/xrayr {start|stop|restart|status}"; exit 1;; esac
EOF
    chmod +x "/etc/init.d/${SERVICE_NAME}"
    if has_cmd update-rc.d; then update-rc.d ${SERVICE_NAME} defaults; fi
    if has_cmd rc-update; then rc-update add ${SERVICE_NAME}; fi
    /etc/init.d/${SERVICE_NAME} start || true
    c_green "已安装 SysV 启动脚本：/etc/init.d/${SERVICE_NAME}"
  fi
}

uninstall_all() {
  c_yellow "开始卸载…"
  if has_cmd systemctl; then
    systemctl disable --now "$SERVICE_NAME" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service" && systemctl daemon-reload || true
  else
    [ -f "/etc/init.d/${SERVICE_NAME}" ] && { /etc/init.d/${SERVICE_NAME} stop || true; rm -f "/etc/init.d/${SERVICE_NAME}"; }
  fi
  rm -rf "$XRAYR_DIR" "$CONF_DIR" /usr/local/bin/XrayR
  id -u xrayr >/dev/null 2>&1 && userdel xrayr 2>/dev/null || true
  c_green "卸载完成"
}

show_menu() {
  echo "\n========== SSPanel UIM 一键对接（XrayR）=========="
  echo "1) 安装/更新 XrayR"
  echo "2) 生成/更新 配置"
  echo "3) 启动/重启 服务"
  echo "4) 查看运行状态"
  echo "5) 卸载"
  echo "0) 退出"
  read -rp "请选择: " ans
  case "$ans" in
    1) choose_pm; install_basics; file=$(fetch_latest); install_xrayr "$file"; c_green "安装完成"; install_service ;;
    2) make_config; if has_cmd systemctl; then systemctl restart "$SERVICE_NAME"; else /etc/init.d/${SERVICE_NAME} restart || true; fi ;;
    3) if has_cmd systemctl; then systemctl restart "$SERVICE_NAME" && systemctl enable "$SERVICE_NAME"; else /etc/init.d/${SERVICE_NAME} restart || true; fi ;;
    4) if has_cmd systemctl; then systemctl status "$SERVICE_NAME" --no-pager; else /etc/init.d/${SERVICE_NAME} status || true; fi ;;
    5) uninstall_all ;;
    0) exit 0 ;;
    *) echo "无效选择" ;;
  esac
}

need_root
mkdir -p "$CONF_DIR"
while true; do
  show_menu
  echo
  read -rp "按回车返回菜单…" _
done
