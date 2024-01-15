#!/bin/bash

# Function to print titles in bold and underlined
print_title() {
    echo -e "\033[1m\033[4m$1\033[0m"
}

#     if [[ $host == "iwg26-v3*" ]]; then echo "YESS" fi;;

# if echo "$(hostname)" | grep -q "^iwg26-v2"; then echo yeeees; fi
# elif echo "$(hostname)" | grep -q "^iwg26-v3"; then
#     IFACE=wwan0
# else
#     IFACE=unknown
# fi

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
        echo "Modem is not online, no IP address found"
        return 1  # Return a non-zero exit code for failure
    else
        echo "IP Address is: $ip_address"
        return 0  # Return zero for success
    fi
}

get_state_info() {
    sudo cc-pmcli gpios 
    # echo "------------------"
    # sudo cc-pmcli state | tr ',' '\n' | awk -F: '{print $1 ": " $2}'
    # echo "------------------"

}
# Main code wrapped in a function for ease of testing
main() {
    echo "second arg: $2"

    print_title "Device type:"
    hostname

    print_title "SW versions:"
    sudo cc-hal updatecli versions

    print_title "Device:"
    cc-info

    print_title "Onomondo addr:"
    local host=$(hostname)

    local iface=$(determine_iface $host)
    get_ip_address $iface

    print_title "State:"
    get_state_info
}

# Call the main function
main
