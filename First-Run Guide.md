# Step-CA: Root Certificate Trust Guide

Because sovereign-stack uses a private Certificate Authority (Step-CA), 
your devices will not recognize your local SSL certificates by default. 
You must install the Root Certificate on every device that accesses 
the stack.

## 1. Export the Root Certificate
First, you need to get the `root_ca.crt` file from your Raspberry Pi 
to your computer or phone. Run this on your Pi:

    cp ${DOCKER_ROOT}/step-ca/certs/root_ca.crt ~/root_ca.crt

Transfer this file to your device via SFTP, email, or a USB stick.

## 2. Installation per Device Type

### Windows 10/11
1. Double-click the `root_ca.crt` file.
2. Click **Install Certificate...**
3. Select **Local Machine** and click Next.
4. Select **Place all certificates in the following store**.
5. Click **Browse** and select **Trusted Root Certification Authorities**.
6. Finish the wizard and restart your browser.

### Android (13+)
1. Settings -> Security & Privacy -> More Security Settings.
2. Encryption & credentials -> Install a certificate.
3. Select **CA certificate**.
4. Tap **Install anyway** (warning) and select your `root_ca.crt`.

### iOS / iPhone
1. Send the file via AirDrop or Files app.
2. Open **Settings** -> **Profile Downloaded** -> **Install**.
3. **Crucial Step:** Go to Settings -> General -> About -> 
   **Certificate Trust Settings**.
4. Enable full trust for your Sovereign Root CA.

## 3. Browser Specifics (Firefox)
Firefox does not use the System Trust Store. You must import it manually:
1. Settings -> Privacy & Security.
2. Scroll to **Certificates** -> **View Certificates**.
3. Under the **Authorities** tab, click **Import**.
4. Select `root_ca.crt` and check **"Trust this CA to identify websites"**.
