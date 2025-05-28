#!/bin/bash

# Telegram Bot Configuration
BOT_TOKEN=""
CHAT_ID=""

# Extract the latest block height from local node logs
log_block_height=$(tail -n 1000 /var/log/redbelly/rbn_logs/rbbc_logs.log | grep "number" | sed -E 's/.*"number": "([0-9]+)".*/\1/' | tail -n 1)

# Fetch the latest block height from the Redbelly MAINNET RPC endpoint
latest_block_height=$(curl -s https://governors.mainnet.redbelly.network -X POST -H "Content-Type: application/json" \
--data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' \
| jq -r '.result.number' | xargs -I {} printf "%d\n" {})

# Calculate the absolute difference
difference=$(echo "$log_block_height $latest_block_height" | awk '{print ($1 > $2) ? $1 - $2 : $2 - $1}')

# Get system info
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//')
ram_used=$(free -m | awk '/Mem:/ {print $3}')
ram_total=$(free -m | awk '/Mem:/ {print $2}')
disk_usage=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')

# Only send notification if not synced
if [ "$difference" -gt 1 ]; then
    sync_status="❌ <b>Not Synced</b>"

    html_message="<b>🧾 Node Sync Status (Mainnet)</b>%0A"
    html_message+="<b>🕒 Time:</b> $timestamp%0A"
    html_message+="<b>📦 Node Block:</b> $log_block_height%0A"
    html_message+="<b>🌐 Network Block:</b> $latest_block_height%0A"
    html_message+="<b>📉 Difference:</b> $difference blocks%0A"
    html_message+="<b>📊 Status:</b> $sync_status%0A"
    html_message+="%0A"
    html_message+="<b>💻 System Info</b>%0A"
    html_message+="<b>🧠 CPU Load:</b> $cpu_load%0A"
    html_message+="<b>🗂 RAM:</b> ${ram_used}MB / ${ram_total}MB%0A"
    html_message+="<b>💽 Disk:</b> $disk_usage"

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$html_message" \
        -d "parse_mode=HTML"
fi
