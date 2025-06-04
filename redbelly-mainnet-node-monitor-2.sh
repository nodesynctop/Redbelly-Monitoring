#!/bin/bash
# Replace your redbelly hostname
NODE_LINK=""
# Telegram Bot Configuration
# Telegram Bot token - replace with your own bot token
BOT_TOKEN=""

# Telegram Chat ID - replace with your own chat ID
CHAT_ID=""
# This is the message ID you want to update.
MESSAGE_ID=""

check_ssl() {
    SSL_CHECK=$(curl -m 5 -v "${NODE_LINK}:1111" 2>&1 | awk '/expire / {printf $4$5}')

    # Kiểm tra xem SSL_CHECK có giá trị không (tức là link tồn tại và trả về dữ liệu)
    if [ -n "$SSL_CHECK" ]; then
        SSL_VALID=$((($(date +%s -d "$SSL_CHECK") - $(date +%s)) / 86400))
        echo "SSL left: $SSL_VALID days"
        # Chỉ gửi cảnh báo nếu SSL_VALID < 15
        if [ "$SSL_VALID" -lt 15 ]; then
            send_telegram "🔴 <b>WARNING: SSL will expire in $SSL_VALID days.</b>"
        fi
    else
        echo "SSL check failed: Unable to connect to ${NODE_LINK}:1111"
        SSL_VALID="N/A"  # Gán giá trị mặc định khi không check được
    fi
}

# Send the message to Telegram using Bot API
send_telegram() {
    local html_message="$1"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d "text=$html_message" \
        -d "parse_mode=HTML")
}

update_telegram() {
    local html_message="$1"
    #Đặt tin nhắn telegram trong thẻ code
    #local message_pre="$1"
    #local html_message="<code>$message_pre</code>"

    local message_id
    local response

    # Try to update the message
    response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" \
        -d chat_id="$CHAT_ID" \
        -d message_id="$MESSAGE_ID" \
        -d parse_mode="HTML" \
        -d text="$html_message")
}

get_block_heights() {
    # Extract the latest block height from local node logs
    log_block_height=$(tail -n 1000 /var/log/redbelly/rbn_logs/rbbc_logs.log | grep "number" | sed -E 's/.*"number": "([0-9]+)".*/\1/' | tail -n 1)

    # Fetch the latest block height from the Redbelly MAINNET RPC endpoint
    latest_block_height=$(curl -s https://governors.mainnet.redbelly.network -X POST -H "Content-Type: application/json" \
    --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' \
    | jq -r '.result.number' | xargs -I {} printf "%d\n" {})

    # Calculate the absolute difference between the local and network block height
    difference=$(echo "$log_block_height $latest_block_height" | awk '{print ($1 > $2) ? $1 - $2 : $2 - $1}')

    # Determine sync status based on difference
    if [ "$difference" -le 1 ]; then
        sync_status="✅ <b>Synced</b>"
    else
        sync_status="❌ <b>Not Synced</b>"
        send_telegram "❌ <b>Alert: Your Redbelly node is out of sync!</b>"
    fi
}

main() {
    check_ssl
    get_block_heights
    # Get current timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Get system resource usage
    cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//')
    ram_used=$(free -m | awk '/Mem:/ {print $3}')
    ram_total=$(free -m | awk '/Mem:/ {print $2}')
    disk_usage=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')

    # Build HTML message to send to Telegram
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
    html_message+="<b>💽 Disk:</b> $disk_usage%0A"
    html_message+="<b>SSL valid:</b> $([ "$SSL_CHECK" != "N/A" ] && date -d "$SSL_CHECK" +'%d/%m/%Y' || echo "N/A") ($SSL_VALID days left)"

    # update message
    update_telegram "$html_message"
}
# Execute
main
