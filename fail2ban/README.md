# Sovereign Stack - Fail2ban Configuration

This directory contains Fail2ban configuration for the Sovereign Stack.

## Files

- `data/jail.local` - Jail definitions for Nextcloud, NPM, Forgejo
- `data/filter.d/nextcloud.conf` - Nextcloud login failure filter
- `data/action.d/` - Custom actions (optional)

## Setup

1. **Mount Nextcloud logs** (already added to docker-compose.yaml):
   ```yaml
   - "${DOCKER_ROOT}/nextcloud/data:/var/log/nextcloud:ro"
   ```

2. **Restart Fail2ban container**:
   ```bash
   docker compose restart fail2ban
   ```

3. **Verify jails are active**:
   ```bash
   docker exec fail2ban fail2ban-client status
   ```

4. **Test Nextcloud filter**:
   ```bash
   docker exec fail2ban fail2ban-client status nextcloud
   ```

## Customization

Edit `jail.local` to adjust:
- `bantime` - Duration of ban (default: 3600 seconds = 1 hour)
- `findtime` - Time window for maxretry (default: 600 seconds = 10 minutes)
- `maxretry` - Failed attempts before ban (default: 5)

## Troubleshooting

Check fail2ban logs:
```bash
docker logs fail2ban
```

Unban an IP:
```bash
docker exec fail2ban fail2ban-client set nextcloud unbanip <IP_ADDRESS>
```

Whitelist an IP:
Add to `jail.local`:
```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.178.0/24
```
