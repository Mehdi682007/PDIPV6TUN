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
    echo "| 4) Add Cron Job for Tunnel      |"
    echo "| 5) Show Cron Jobs               |"
    echo "| 6) Remove Cron Job              |"
    echo "| 7) Remove Tunnel                |"
    echo "| 8) Exit                         |"
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

            # تعیین نام مناسب برای تونل جدید
            LAST_NUM=$(grep -oE 'tunnel-PD[0-9]*' /etc/rc.local 2>/dev/null | sed 's/tunnel-PD//' | sort -n | tail -n 1)
            if [ -z "$LAST_NUM" ]; then
                NEXT_NUM=0
            else
                NEXT_NUM=$((LAST_NUM + 1))
            fi
            TUNNEL_NAME="tunnel-PD$NEXT_NUM"

            # ایجاد تونل
            sudo ip tunnel add $TUNNEL_NAME mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
            sudo ip link set dev $TUNNEL_NAME up mtu 1500
            sudo ip addr add $LOCAL_IPV6/64 dev $TUNNEL_NAME
            sudo ip link set $TUNNEL_NAME mtu 1436
            sudo ip link set $TUNNEL_NAME up

            # اطمینان از وجود فایل و تنظیمات rc.local
            if [ ! -f /etc/rc.local ]; then
                echo "#!/bin/bash" | sudo tee /etc/rc.local > /dev/null
            fi

            FIRST_LINE=$(head -n 1 /etc/rc.local)
            if [[ "$FIRST_LINE" != "#!/bin/bash" ]]; then
                sudo sed -i '1s/.*/#!/bin/bash/' /etc/rc.local
            fi

            sudo sed -i '/^exit 0$/d' /etc/rc.local

            cat <<EOF | sudo tee -a /etc/rc.local > /dev/null

# Tunnel: $TUNNEL_NAME
ip tunnel add $TUNNEL_NAME mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
ip link set dev $TUNNEL_NAME up mtu 1500
ip addr add $LOCAL_IPV6/64 dev $TUNNEL_NAME
ip link set $TUNNEL_NAME mtu 1436
ip link set $TUNNEL_NAME up
EOF

            echo -e "\nexit 0" | sudo tee -a /etc/rc.local > /dev/null
            sudo chmod +x /etc/rc.local

            echo "Tunnel $TUNNEL_NAME added and configured in /etc/rc.local"
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
            echo "Enter IPv6 addresses to ping (separate multiple IPs with space): "
            read IPV6_TARGETS
            echo "Enter interval (seconds) between pings (default is 3): "
            read PING_INTERVAL
            PING_INTERVAL=${PING_INTERVAL:-3}

           # ذخیره کردن IP ها در فایل برای استفاده آینده
           echo "$IPV6_TARGETS" | sudo tee /etc/ping_ipv6_targets > /dev/null

           # شمارش آی‌پی‌ها برای نامگذاری فایل‌ها
           COUNTER=1
           for IPV6_TARGET in $IPV6_TARGETS; do
           # ساخت نام فایل مجزا برای هر IP
           LOG_FILE="/root/ping_output_$COUNTER.log"

           # اجرای پینگ برای هر آی‌پی به‌طور همزمان
           nohup bash -c "while true; do date '+%Y-%m-%d %H:%M:%S'; ping6 -c 1 $IPV6_TARGET | grep -E 'bytes from|icmp_seq'; sleep $PING_INTERVAL; done" > "$LOG_FILE" 2>&1 &

           # افزایش شمارنده برای فایل بعدی
           COUNTER=$((COUNTER+1))
           done

           echo "Persistent IPv6 ping started for the following IPs: $IPV6_TARGETS"
           echo "Output is being logged in separate files under /root/ (ping_output_1.log, ping_output_2.log, etc.)."
           read -p "Press Enter to continue..."
           ;;

        4)
            echo "Enter interval (in hours) to restart tunnel service: "
            read INTERVAL
            CRON_EXPRESSION="0 */$INTERVAL * * * systemctl restart rc-local"
            (crontab -l 2>/dev/null; echo "$CRON_EXPRESSION") | crontab -
            echo "Cron job added to restart tunnel every $INTERVAL hours."
            read -p "Press Enter to continue..."
            ;;

        5)
            echo "Current Cron Jobs:"
            crontab -l
            read -p "Press Enter to continue..."
            ;;

        6)
            crontab -l | grep -v 'systemctl restart rc-local' | crontab -
            echo "Tunnel restart cron job removed."
            read -p "Press Enter to continue..."
            ;;

        7)
            read -p "Are you sure you want to remove all tunnels? (y/n): " CONFIRM_DELETE
            if [[ "$CONFIRM_DELETE" == "y" ]]; then
                echo "Removing tunnels..."
                for IFACE in $(ip -o link show | awk -F': ' '{print $2}' | grep '^tunnel-PD'); do
                    sudo ip link set "$IFACE" down
                    sudo ip tunnel del "$IFACE"
                done
                sudo rm -f /etc/rc.local /etc/ping_ipv6_target /etc/ping_interval
                echo "Tunnels removed successfully."
                read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
                if [[ "$REBOOT_CHOICE" == "y" ]]; then
                    sudo reboot
                fi
            else
                echo "Tunnel removal canceled."
            fi
            read -p "Press Enter to continue..."
            ;;

        8)
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "Invalid option!"
            read -p "Press Enter to continue..."
            ;;
    esac
done
