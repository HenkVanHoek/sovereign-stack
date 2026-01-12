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
