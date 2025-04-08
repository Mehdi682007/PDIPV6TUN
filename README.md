[English](https://github.com/Mehdi682007/PDIPV6TUN/blob/main/README.md)  | [Persian](https://github.com/Mehdi682007/PDIPV6TUN/blob/main/README.fa.md)

# PDIPV6TUN
IPV6 Tunnel High Speed

- Donate Me
- Tron(TRX) `TRwa4tZretyDndiUwCEZYokKoe1ezSQxsE`
</br>
</br>

## IPv6 Tunnel Script
### Usage:
To use the script, simply run the following command to download and execute it:
# Install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PDIPV6TUN/main/install.sh)

```

# For install costum Version , Replace v1.0.1 with the desired version.
```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PDIPV6TUN/v1.0.1/install.sh)
```

# Tutorial Video :
[![Example Video](https://i9.ytimg.com/vi_webp/py0WkHCYi28/mqdefault.webp?v=67ee74a4&sqp=CKyo1r8G&rs=AOn4CLC2cgNk3AQ9zpO_O8OtkxUkjwRgXQ)](https://youtu.be/py0WkHCYi28)
Explanation of the PDIPV6TUN Installer Script:
PDIPV6TUN Installer

This script is designed to help you easily set up and manage a IPv6 Tunnel on your server. The script provides a simple user interface for installing, checking, and removing the tunnel, along with additional features for server reboot management. It is ideal for users looking to configure an IPv6 tunnel for secure and reliable network communication.

Features:
Install Tunnel:

The script allows users to add a Sit Tunnel (IPv6 over IPv4) to the server, specifying remote and local IPv4 addresses and a local IPv6 address.

It automatically configures the tunnel to start at boot by adding the necessary commands to /etc/rc.local.

Show Assigned Local IPv6:

Displays the currently assigned local IPv6 address for the tunnel from /etc/rc.local.

Remove Tunnel:

Allows the user to remove the tunnel from the server, including stopping the tunnel, deleting the tunnel interface, and cleaning up configuration from /etc/rc.local.

A confirmation step is required before removing the tunnel.

Server Reboot:

After installation or removal of the tunnel, the script gives the user an option to reboot the server immediately to apply changes.

Status Check:

Displays whether the tunnel is installed or not with colored indicators.

If installed, it shows a green "✅ Installed" status; otherwise, it shows a red "❌ Not Installed" status.

Requirements:
sudo privileges: The script requires administrative privileges to configure networking interfaces and modify /etc/rc.local.

iproute2: This package is required for network interface management.

The script will present the following options to the user:

Install Tunnel: Add a new IPv6 tunnel.

Show Assigned Local IPv6: Show the currently configured IPv6 address.

Remove Tunnel: Remove the configured tunnel.

Exit: Exit the script.

Example Flow:
After running the script, choose 1) Install Tunnel to configure the tunnel.

Enter the required addresses for the tunnel setup.

Optionally, reboot the server to apply the changes.

Use 2) Show Assigned Local IPv6 to check the IPv6 address.

If you wish to remove the tunnel, select 3) Remove Tunnel and confirm the removal.

Notes:
The script works on Linux-based systems that support ip command and /etc/rc.local configuration.

Be careful when removing the tunnel, as it will delete configuration from /etc/rc.local and may require manual cleanup in some cases.


