#!/bin/bash
SSH_CONFIG_FILE="$HOME/.ssh/config"
IMPORT_FILE="$HOME/ssh_hosts.txt"

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch "$SSH_CONFIG_FILE"
chmod 600 "$SSH_CONFIG_FILE"

if [ -f "$IMPORT_FILE" ]; then
  while IFS=',' read -r host alias user keyfile port; do
    [ -z "$host" ] && continue
    if grep -q "^Host[[:space:]]\+$alias" "$SSH_CONFIG_FILE"; then
      echo "⚠️ 别名 '$alias' 已存在，跳过导入"
      continue
    fi
    {
      echo "Host $alias"
      echo "    HostName $host"
      echo "    User ${user:-root}"
      [ -n "$keyfile" ] && echo "    IdentityFile ${keyfile/#\~/$HOME}"
      [ -n "$port" ] && echo "    Port $port"
      echo ""
    } >> "$SSH_CONFIG_FILE"
    echo "✅ 已导入主机 $alias ($host)"
  done < "$IMPORT_FILE"
else
  echo "⚠️ 未检测到 $IMPORT_FILE，跳过批量导入"
fi
