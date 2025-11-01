#!/bin/bash

USER="yuklia"
KEY="~/.ssh/homelab-k8s-pi"
SSH_ARGS="-i $KEY -o StrictHostKeyChecking=no"

HOSTS=(
  "localhost"
  "192.168.101.11"
  "192.168.101.12"
  "192.168.101.13"
  "192.168.101.14"
)

# Відкриваємо нове вікно Terminal і підключаємося до першого хоста в першій вкладці
osascript <<EOF
tell application "Terminal"
  activate
  do script "ssh $SSH_ARGS $USER@${HOSTS[0]}"
end tell
EOF

# Дати трохи часу Terminal відкрити вікно
sleep 2

# Інші хости – в нових вкладках того ж вікна
for ((i = 1; i < ${#HOSTS[@]}; i++)); do
  HOST="${HOSTS[$i]}"
  osascript <<EOF
tell application "Terminal"
  activate
  tell application "System Events" to keystroke "t" using command down
  delay 0.2
  do script "ssh $SSH_ARGS $USER@$HOST" in selected tab of the front window
end tell
EOF
  sleep 0.5
done
