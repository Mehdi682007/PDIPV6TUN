#!/bin/bash

# بررسی وضعیت نصب تونل
if grep -q "tunnel-PD" /etc/rc.local 2>/dev/null; then
    STATUS="\e[32m\xE2\x9C\x85 Installed\e[0m"  # رنگ سبز برای نصب شده
else
    STATUS="\e[31m\xE2\x9D\x8C Not Installed\e[0m"  # رنگ قرمز برای نصب نشده
fi

while true; do
    clear
    echo -e "========================================="
    echo -e "\e[34;1m      PDIPV6TUN Installer     \e[0m"
    echo -e "========================================="
    echo -e "| Tunnel Status: $STATUS          |"
    echo -e "========================================="
    echo "| 1) Install Tunnel               |"
    echo "| 2) Show Assigned Local IPv6     |"
    echo "| 3) Start Persistent IPv6 Ping   |"
    echo "| 4) View Ping Log                |"
    echo "| 5) Add Cron Job for Tunnel      |"
    echo "| 6) Show Cron Jobs               |"
    echo "| 7) Remove Cron Job              |"
    echo "| 8) Remove Tunnel                |"
    echo "| 9) Exit                         |"
    echo "========================================="
    read -p "Select an option: " OPTION

    case $OPTION in
        1)
            echo "Enter remote IPv4 address: "
            read REMOTE_IP
            LOCAL_IP=$(hostname -I | awk '{print $1}')
            echo "Detected local IPv4: $LOCAL_IP"
            echo "Enter local IPv6 address: "
            read LOCAL_IPV6

            sudo rm -f /etc/rc.local

            sudo ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
            sudo ip link set dev tunnel-PD up mtu 1500
            sudo ip addr add $LOCAL_IPV6/64 dev tunnel-PD
            sudo ip link set tunnel-PD mtu 1436
            sudo ip link set tunnel-PD up

            cat <<EOF | sudo tee /etc/rc.local
#!/bin/bash

ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
ip link set dev tunnel-PD up mtu 1500
ip addr add $LOCAL_IPV6/64 dev tunnel-PD
ip link set tunnel-PD mtu 1436
ip link set tunnel-PD up

if [ -f /etc/ping_ipv6_target ]; then
    IPV6_TARGET=\$(cat /etc/ping_ipv6_target)
    if [ -f /etc/ping_interval ]; then
        PING_INTERVAL=\$(cat /etc/ping_interval)
    else
        PING_INTERVAL=3
    fi
    nohup bash -c "while true; do date '+%Y-%m-%d %H:%M:%S'; ping6 -c 1 \$IPV6_TARGET | grep -E 'bytes from|icmp_seq'; sleep \$PING_INTERVAL; done" > /root/ping_output.log 2>&1 &
fi

exit 0
EOF

            sudo chmod +x /etc/rc.local

            echo "Tunnel setup completed and configured in /etc/rc.local"
            read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
            if [[ "$REBOOT_CHOICE" == "y" ]]; then
                sudo reboot
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            echo "Assigned Local IPv6 Address:"
            grep -oP 'ip addr add \K[^ ]+' /etc/rc.local 2>/dev/null || echo "No IPv6 assigned."
            read -p "Press Enter to continue..."
            ;;
        3)
            echo "Enter IPv6 address to ping: "
            read IPV6_TARGET
            echo "Enter interval (seconds) between pings (default is 3): "
            read PING_INTERVAL
            PING_INTERVAL=${PING_INTERVAL:-3}

            echo "$IPV6_TARGET" | sudo tee /etc/ping_ipv6_target > /dev/null
            echo "$PING_INTERVAL" | sudo tee /etc/ping_interval > /dev/null

            nohup bash -c "while true; do date '+%Y-%m-%d %H:%M:%S'; ping6 -c 1 $IPV6_TARGET | grep -E 'bytes from|icmp_seq'; sleep $PING_INTERVAL; done" > /root/ping_output.log 2>&1 &
            echo "Persistent IPv6 ping started to $IPV6_TARGET every $PING_INTERVAL seconds. Output is being logged in /root/ping_output.log."
            read -p "Press Enter to continue..."
            ;;
        4)
            nano /root/ping_output.log
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "Enter interval (in hours) to restart tunnel service: "
            read INTERVAL
            CRON_EXPRESSION="0 */$INTERVAL * * * systemctl restart rc-local"
            (crontab -l 2>/dev/null; echo "$CRON_EXPRESSION") | crontab -
            echo "Cron job added to restart tunnel every $INTERVAL hours."
            read -p "Press Enter to continue..."
            ;;
        6)
            echo "Current Cron Jobs:"
            crontab -l
            read -p "Press Enter to continue..."
            ;;
        7)
            crontab -l | grep -v 'systemctl restart rc-local' | crontab -
            echo "Tunnel restart cron job removed."
            read -p "Press Enter to continue..."
            ;;
        8)
            read -p "Are you sure you want to remove the tunnel? (y/n): " CONFIRM_DELETE
            if [[ "$CONFIRM_DELETE" == "y" ]]; then
                echo "Removing tunnel..."
                sudo ip link set tunnel-PD down
                sudo ip tunnel del tunnel-PD
                sudo rm -f /etc/rc.local /etc/ping_ipv6_target /etc/ping_interval
                echo "Tunnel removed successfully."
                read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
                if [[ "$REBOOT_CHOICE" == "y" ]]; then
                    sudo reboot
                fi
            else
                echo "Tunnel removal canceled."
            fi
            read -p "Press Enter to continue..."
            ;;
        9)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option!"
            read -p "Press Enter to continue..."
            ;;
    esac
done
