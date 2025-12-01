#!/bin/sh

# Pick the best IPv4 address by interface priority.
# Prefer modem links (ppp0/wwan0), then USB ethernet variants, then any global IPv4.

get_ipv4() {
    iface=$1
    ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
}

is_private() {
    case "$1" in
        10.*|192.168.*|172.16.*|172.17.*|172.18.*|172.19.*|172.20.*|172.21.*|172.22.*|172.23.*|172.24.*|172.25.*|172.26.*|172.27.*|172.28.*|172.29.*|172.30.*|172.31.*)
            return 0;;
    esac
    return 1
}

found_private=""

# Preferred interfaces in order
for iface in ppp0 wwan0 usb usb0 usb1 usb2 eth0; do
    ip_address=$(get_ipv4 "$iface")
    if [ -n "$ip_address" ]; then
        if is_private "$ip_address"; then
            found_private="$ip_address"
            continue
        fi
        echo "$ip_address"
        exit 0
    fi
done

# Fallback: any non-loopback global IPv4 (still prefer non-private)
ip_address=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
if [ -n "$ip_address" ] && ! is_private "$ip_address"; then
    echo "$ip_address"
    exit 0
fi

printf "\033[31mNo IP address found, is modem online?\033[0m\n"
exit 1
