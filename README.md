# TenantOS and FastNetMon Integration

A robust notification system for FastNetMon that sends beautifully formatted HTML emails to server owners when their IPs are banned or unbanned due to DDoS attacks.

## Features

- 🚨 Instant DDoS attack notifications
- 📧 Beautiful HTML email templates
- 🔄 Automatic IP owner lookup
- 🔐 Ban and unban status updates
- 📊 Attack statistics in notifications
- 🛡️ Security recommendations included

## Prerequisites

- FastNetMon Community Edition installed
- `swaks` for sending emails
- `jq` for JSON processing
- `curl` for API requests

## Installation

1. Clone this repository:
```bash
git clone https://github.com/UK-NOC/tenantos-fastnetmon.git
cd tenantos-fastnetmon
```

2. Copy the scripts to FastNetMon directory:
```bash
sudo cp ip_ban_notifier.sh /opt/fastnetmon-community/
sudo chmod +x /opt/fastnetmon-community/ip_ban_notifier.sh
```

3. Configure FastNetMon to use the notification script:
```bash
sudo cp notify_about_attack.sh /opt/fastnetmon/
sudo chmod +x /opt/fastnetmon/notify_about_attack.sh
```

## Configuration

1. Edit `/opt/fastnetmon/notify_about_attack.sh`:
```bash
#!/bin/bash
/opt/fastnetmon-community/actions.sh $1 $2 $3 $4
/opt/fastnetmon-community/ip_ban_notifier.sh $1 $2 $3 $4
exit 0
```

2. Configure the `ip_ban_notifier.sh` script:
```bash
# API Configuration
API_BASE_URL="https://your-api-url/api"
API_KEY="your-api-key-here"

# Email Configuration
SMTP_SERVER="mail.your-domain.com"
SMTP_PORT="587"
SMTP_USER="notifications@your-domain.com"
SMTP_PASS="your-smtp-password"
FROM_EMAIL="notifications@your-domain.com"
FROM_NAME="Security Team"
```

## Usage

The script is automatically called by FastNetMon when an attack is detected. The parameters are:

```bash
ip_ban_notifier.sh <client_ip> <direction> <pps> <action>
```

Where:
- `client_ip`: The IP address being banned/unbanned
- `direction`: Traffic direction (inbound/outbound)
- `pps`: Packets per second
- `action`: Either "ban" or "unban"

Example:
```bash
./ip_ban_notifier.sh 192.168.1.1 inbound 1000 ban
```

## Email Templates

The script includes two professionally designed HTML email templates:

1. **Ban Notification**
   - Attack details
   - Mitigation status
   - Required actions
   - Security recommendations

2. **Unban Notification**
   - Previous attack details
   - Security recommendations
   - Next steps

## API Integration

The script integrates with your TenantOS API to:
- Look up IP ownership
- Get server details
- Update IP ban status
- Fetch user contact information

## Customization

You can customize the email templates by modifying the HTML/CSS in the script. The templates use:
- Responsive design
- Color-coded sections
- Clear typography
- Professional formatting

## Troubleshooting

1. **Emails not sending**
   - Check SMTP credentials
   - Verify server connectivity
   - Check mail logs

2. **API errors**
   - Verify API key
   - Check API endpoint URL
   - Ensure proper permissions

3. **Script not executing**
   - Check file permissions
   - Verify FastNetMon configuration
   - Check system logs

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request





## Support

For issues and feature requests, please use the GitHub issue tracker.
