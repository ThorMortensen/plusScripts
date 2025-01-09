#!/bin/bash


# Function to determine the network interface based on hostname
determine_iface() {
    local host=$1
    if echo "$(hostname)" | grep -q "^iwg26-v2"; then
        echo "ppp0"
    elif echo "$(hostname)" | grep -q "^iwg26-v3"; then
        echo "wwan0"
    else
        echo "unknown"
    fi

}

get_ip_address() {
    local iface="$1"

    # Try to get the IP address
    local ip_address=$(sudo ifconfig "$iface" 2>/dev/null | grep 'inet addr:' | awk -F: '{print $2}' | awk '{print $1}')

    # Check if we were successful
    if [ -z "$ip_address" ]; then
         echo -e "\033[31mNo IP address found, is modem online?\033[0m" 
        return 1  # Return a non-zero exit code for failure
    else
        echo "$ip_address"
        return 0  # Return zero for success
    fi
}


main() {

    local host=$(hostname)

    local iface=$(determine_iface $host)
    get_ip_address $iface
}

main
