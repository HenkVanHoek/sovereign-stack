# Troubleshooting SSL/Browser issues

## Browser remembers old certificate (HSTS)
If you recently changed your SSL certificate (e.g., from Let's Encrypt to Smallstep or vice versa) and the browser shows a security warning, you may need to clear the HSTS cache.

### Chrome/Edge/Brave
1. Navigate to `chrome://net-internals/#hsts`
2. Under "Delete domain security policies", enter your domain: `npm.piselfhosting.com`
3. Click "Delete".

### Firefox
1. Open History (`Ctrl + Shift + H`).
2. Right-click on the domain and select "Forget About This Site".

## NPM Certificate Mismatch
Ensure that the correct certificate is selected in the Nginx Proxy Manager UI under:
`Proxy Hosts` -> `Edit` -> `SSL` -> `SSL Certificate`.

## Troubleshooting: External IP detected via VPN
    When using Wireguard, Nginx Proxy Manager may see your public WAN IP 
    (from your provider, e.g., Freedom Internet) instead of your internal 
    VPN IP.

    ### Diagnosis
    Check the specific proxy logs to see which client IP is being blocked:
    `docker exec -it <npm_container> cat /data/logs/proxy-host-5_access.log | grep 403`

    ### Solution
    Since this project uses a fixed public IP (Freedom Internet), add your 
    own public IPv4 address to the NPM Access List. This ensures that 
    even when the VPN "masquerades" the traffic through the public gateway, 
    access is still granted.

## Troubleshooting: Permission Denied on Step-CA
If the `step-ca` container fails to start with a 'Permission denied' 
error in the logs, ensure the host directory has the correct UID 
ownership. The container user (step) requires UID 1000.

Fix:
`sudo chown -R 1000:1000 ${DOCKER_ROOT}/step-ca`

## Post-Configuration Note: Browser Caching & Service Workers
    After correcting environment variables (like `DOMAIN`), a simple 
    browser restart may not be sufficient to resolve 'Fetch Errors'.

    ### Observations:
    - Modern browsers utilize Service Workers and background sync that 
      can persist even after a restart.
    - These processes may hold onto invalid CSRF tokens or session 
      headers that don't match the new server configuration.
    
    ### Recommended Recovery Steps:
    1. Fully log out of the Bitwarden Vault.
    2. Clear site data/cache specifically for the vault domain.
    3. If issues persist, a full system network stack reset (or 
       sleep/wake cycle) can force a re-handshake with the proxy, 
       clearing stale background processes.
