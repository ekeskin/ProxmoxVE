#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Kristian Skov - Updated by Erdem Keskin
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.microsoft.com/en-us/sql-server/sql-server-2025

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  coreutils \
  gnupg2 \
  curl
msg_ok "Installed Dependencies"

msg_info "Setup SQL Server 2025"
# Import the public GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
# Register the SQL Server 2025 Ubuntu 24.04 repository
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list | tee /etc/apt/sources.list.d/mssql-server-2025.list >/dev/null

$STD apt-get update -y
$STD apt-get install -y mssql-server
msg_ok "Setup Server 2025"

msg_info "Installing SQL Server Tools"
export DEBIAN_FRONTEND=noninteractive
export ACCEPT_EULA=Y

# Register the Microsoft Ubuntu 24.04 repository for tools (mssql-tools18)
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list >/dev/null

$STD apt-get update
$STD apt-get install -y -qq \
  mssql-tools18 \
  unixodbc-dev

# Update PATH for the current session and persistence
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
export PATH="$PATH:/opt/mssql-tools18/bin"
msg_ok "Installed SQL Server Tools"

read -r -p "${TAB3}Do you want to run the SQL server setup now? (Later is also possible) <y/N>" prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  /opt/mssql/bin/mssql-conf setup
else
  msg_ok "Skipping SQL Server setup. You can run it later with '/opt/mssql/bin/mssql-conf setup'."
fi

msg_info "Start Service"
systemctl enable -q --now mssql-server
msg_ok "Service started"

motd_ssh
customize
cleanup_lxc
