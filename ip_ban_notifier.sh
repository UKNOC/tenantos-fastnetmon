#!/bin/bash

# IP Ban Notification Script
# This script finds the owner of an IP address and sends notification emails about DDoS attacks and IP bans
#
# Script parameters:
#  $1 client_ip_as_string - The IP address to ban/unban
#  $2 data_direction - Direction of the attack (inbound/outbound)
#  $3 pps_as_string - Packets per second
#  $4 action - Action to take (ban/unban)
#
# Example: ./ip_ban_notifier.sh 192.168.1.1 inbound 1000 ban

# Configuration - Replace with your values
API_BASE_URL="https://your-api-url/api"
API_KEY="your-api-key-here"

# Email Configuration - Replace with your values
SMTP_SERVER="mail.your-domain.com"
SMTP_PORT="587"
SMTP_USER="notifications@your-domain.com"
SMTP_PASS="your-smtp-password"
FROM_EMAIL="notifications@your-domain.com"
FROM_NAME="Security Team"

# Debug mode (set to false to disable debug output)
DEBUG_MODE=false

# Function to make API calls silently
make_api_call() {
    local endpoint=$1
    curl -s \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        "${API_BASE_URL}${endpoint}"
}

# Function to get user email by user ID silently
get_user_email() {
    local user_id=$1
    local user_response=$(make_api_call "/users/$user_id")
    local email=$(echo "$user_response" | grep -o '"email":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "$email"
}

# Function to find IP owner using API silently
find_ip_owner() {
    local ip=$1
    echo "Looking up IP owner..."
    
    # Get all servers
    local servers_response=$(make_api_call "/servers")
    
    if [ -z "$servers_response" ]; then
        echo "Error: No response from API"
        return 1
    fi
    
    # Extract all server blocks that might contain our IP
    local matching_servers=$(echo "$servers_response" | jq -r --arg ip "$ip" '.result[] | select(.primaryip == $ip)')
    
    if [ -n "$matching_servers" ]; then
        # Extract server details
        SERVER_ID=$(echo "$matching_servers" | jq -r '.id')
        OWNER_NAME=$(echo "$matching_servers" | jq -r '.owner_realname')
        SERVER_NAME=$(echo "$matching_servers" | jq -r '.servername')
        local user_id=$(echo "$matching_servers" | jq -r '.user_id')
        
        if [ -n "$user_id" ] && [ "$user_id" != "null" ]; then
            OWNER_EMAIL=$(get_user_email "$user_id")
            echo "Found server: $SERVER_NAME"
            echo "Owner: $OWNER_NAME"
            echo "Email: $OWNER_EMAIL"
            return 0
        fi
    fi
    
    echo "IP owner not found."
    return 1
}

# Function to send email notification
send_email() {
    local to_email=$1
    local subject=$2
    local body=$3
    
    # Create temporary file for email content
    local temp_file=$(mktemp)
    
    # Write email content to temporary file
    cat > "$temp_file" << EOF
$body
EOF
    
    # Send email using swaks
    if swaks --server "$SMTP_SERVER:$SMTP_PORT" \
        --tls \
        --auth LOGIN \
        --auth-user "$SMTP_USER" \
        --auth-password "$SMTP_PASS" \
        --from "$FROM_EMAIL" \
        --to "$to_email" \
        --h-From: "$FROM_NAME <$FROM_EMAIL>" \
        --h-Subject: "$subject" \
        --h-Content-Type: "text/html; charset=UTF-8" \
        --body "$temp_file" \
        --silent 1 >/dev/null 2>&1; then
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Prepare email content
if [ "$MODE" = "ban" ]; then
    SUBJECT="[URGENT] Security Alert: DDoS Attack Detected - $IP"
    EMAIL_CONTENT="<!DOCTYPE html>
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 20px auto; padding: 20px; }
    .header { background-color: #ff4444; color: white; padding: 20px; text-align: center; border-radius: 5px; }
    .content { background-color: #fff; padding: 20px; }
    .details { background-color: #f8f9fa; border-left: 4px solid #ff4444; padding: 15px; margin: 20px 0; }
    .warning { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
    .action { background-color: #e7f3ff; border-left: 4px solid #0d6efd; padding: 15px; margin: 20px 0; }
    .footer { margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }
    ul { list-style-type: none; padding-left: 0; }
    li { margin: 10px 0; padding-left: 20px; position: relative; }
    li:before { content: '•'; position: absolute; left: 0; color: #ff4444; }
</style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h2>⚠️ Security Alert: DDoS Attack Detected</h2>
        </div>
        <div class='content'>
            <p>Dear $OWNER_NAME,</p>
            
            <p>We have detected a DDoS attack originating from your server <strong>$SERVER_NAME</strong>.</p>
            
            <div class='details'>
                <h3>Attack Details:</h3>
                <ul>
                    <li><strong>IP Address:</strong> $IP</li>
                    <li><strong>Direction:</strong> $DIRECTION</li>
                    <li><strong>Rate:</strong> $PPS packets per second</li>
                    <li><strong>Status:</strong> IP Automatically Banned</li>
                </ul>
            </div>

            <div class='warning'>
                <h3>⏳ Mitigation in Progress</h3>
                <p>Our automated DDoS mitigation system has been activated and is currently:</p>
                <ul>
                    <li>Blocking malicious traffic from your IP</li>
                    <li>Protecting our network infrastructure</li>
                    <li>Monitoring for attack cessation</li>
                </ul>
                <p><strong>Note:</strong> Your IP address may be temporarily unavailable or experience limited connectivity until the attack is fully mitigated.</p>
            </div>
            
            <div class='action'>
                <h3>🔒 Required Actions:</h3>
                <ul>
                    <li>Investigate your server for security breaches</li>
                    <li>Check for unauthorized access or compromised services</li>
                    <li>Review your firewall rules and security configurations</li>
                    <li>Update all software to their latest secure versions</li>
                </ul>
            </div>
            
            <div class='footer'>
                <p>Best regards,<br>$FROM_NAME</p>
                <p style='font-size: 11px; color: #999;'>
                    This is an automated security notification.<br>
                    For immediate assistance, please contact our security team.
                </p>
            </div>
        </div>
    </div>
</body>
</html>"
else
    SUBJECT="Security Update: IP Unbanned - $IP"
    EMAIL_CONTENT="<!DOCTYPE html>
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 20px auto; padding: 20px; }
    .header { background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 5px; }
    .content { background-color: #fff; padding: 20px; }
    .details { background-color: #f8f9fa; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; }
    .security { background-color: #e7f3ff; border-left: 4px solid #0d6efd; padding: 15px; margin: 20px 0; }
    .footer { margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }
    ul { list-style-type: none; padding-left: 0; }
    li { margin: 10px 0; padding-left: 20px; position: relative; }
    li:before { content: '•'; position: absolute; left: 0; color: #28a745; }
</style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h2>✅ Security Update: IP Unbanned</h2>
        </div>
        <div class='content'>
            <p>Dear $OWNER_NAME,</p>
            
            <p>We are pleased to inform you that the IP address associated with your server <strong>$SERVER_NAME</strong> has been unbanned and is now allowed back into our network.</p>
            
            <div class='details'>
                <h3>Previous Alert Details:</h3>
                <ul>
                    <li><strong>IP Address:</strong> $IP</li>
                    <li><strong>Direction:</strong> $DIRECTION</li>
                    <li><strong>Rate:</strong> $PPS packets per second</li>
                    <li><strong>Status:</strong> IP Unbanned - Access Restored</li>
                </ul>
            </div>

            <div class='security'>
                <h3>🔒 Security Recommendations:</h3>
                <p>To prevent future incidents, please ensure you:</p>
                <ul>
                    <li>Investigate the root cause of the previous security incident</li>
                    <li>Review and update your security policies</li>
                    <li>Implement additional DDoS protection measures</li>
                    <li>Monitor your server for any unusual activity</li>
                    <li>Keep all software and systems up to date</li>
                </ul>
            </div>
            
            <p>Your server has full network access restored, but please remain vigilant and monitor for any unusual activity.</p>
            
            <div class='footer'>
                <p>Best regards,<br>$FROM_NAME</p>
                <p style='font-size: 11px; color: #999;'>
                    This is an automated security notification.<br>
                    If you need assistance with security measures, please contact our security team.
                </p>
            </div>
        </div>
    </div>
</body>
</html>"
fi

# Main script
if [ $# -lt 4 ]; then
    echo "Usage: $0 <client_ip> <direction> <pps> <action>"
    echo "Parameters:"
    echo "  client_ip  - The IP address to ban/unban"
    echo "  direction  - Direction of the attack (inbound/outbound)"
    echo "  pps       - Packets per second"
    echo "  action    - Action to take (ban/unban)"
    echo ""
    echo "Example: $0 192.168.1.1 inbound 1000 ban"
    exit 1
fi

IP=$1
DIRECTION=$2
PPS=$3
MODE=$4

if [ "$MODE" != "ban" ] && [ "$MODE" != "unban" ]; then
    echo "Invalid mode. Use 'ban' or 'unban'"
    exit 1
fi

# Find IP owner
if ! find_ip_owner "$IP"; then
    echo "Could not find owner for IP: $IP"
    exit 1
fi

# Send email notification
if ! send_email "$OWNER_EMAIL" "$SUBJECT" "$EMAIL_CONTENT"; then
    echo "Failed to send notification for IP: $IP"
    exit 1
fi

# Update IP status in API
if [ "$MODE" = "ban" ]; then
    make_api_call "/ips/$IP/ban" >/dev/null 2>&1
else
    make_api_call "/ips/$IP/unban" >/dev/null 2>&1
fi
