#!/bin/bash

# baseline_menu.sh
#
# Purpose:
# Generate baseline HTTP traffic to a target virtual server using randomized
# URL paths and user agents from local config files.
#
# Prerequisites:
# - curl and shuf must be installed.
# - ./config/useragents_with_bots.txt must exist and contain one user-agent
#   string per line.
# - ./config/urls.txt must exist and contain one URL path per line (for
#   example: / or /index.html).
#
# Configuration:
# - VS_ADDR: target virtual server address.
# - INCREASING_IFACE: source interface/IP for increasing mode.
# - ALT_HIGH_IFACE: source interface/IP used during odd-hour high phase.
# - ALT_LOW_IFACE: source interface/IP used during even-hour low phase.
# - CURL_HTTP_VERSION_FLAG: curl HTTP version flag (default -0 for HTTP/1.0).
#
# Usage:
# 1. Run: ./baseline_menu.sh
# 2. Choose one menu option:
#    - increasing: sends triplets of requests and increases total volume each
#      minute based on the current minute value.
#    - alternate: alternates traffic level by hour (odd hours = higher volume,
#      even hours = lower volume).
#    - Quit: exits the script.
# 3. Press Ctrl-C to stop the active mode and return control.

set -u

VS_ADDR="192.168.57.82"
INCREASING_IFACE="192.168.57.10"
ALT_HIGH_IFACE="192.168.57.10"
ALT_LOW_IFACE="192.168.57.11"

UA_FILE="./config/useragents_with_bots.txt"
URL_FILE="./config/urls.txt"
CURL_HTTP_VERSION_FLAG="-0"

stop_flag=0

require_binary() {
        if ! command -v "$1" >/dev/null 2>&1; then
                echo "Missing dependency: $1"
                exit 1
        fi
}

require_file() {
        if [[ ! -f "$1" ]]; then
                echo "Missing required file: $1"
                exit 1
        fi
}

is_valid_ipv4() {
        local ip="$1"
        local IFS=.
        local octets

        [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
        read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
                ((octet >= 0 && octet <= 255)) || return 1
        done
        return 0
}

validate_addresses() {
        local addr
        for addr in "$VS_ADDR" "$INCREASING_IFACE" "$ALT_HIGH_IFACE" "$ALT_LOW_IFACE"; do
                if ! is_valid_ipv4 "$addr"; then
                        echo "Invalid IPv4 address: $addr"
                        exit 1
                fi
        done
}

pick_random_line() {
        shuf -n 1 "$1"
}

do_report_request() {
        local iface="$1"
        local label="$2"
        local user_agent path url

        user_agent="$(pick_random_line "$UA_FILE")"
        path="$(pick_random_line "$URL_FILE")"
        url="http://${VS_ADDR}${path}"

        curl "$CURL_HTTP_VERSION_FLAG" --interface "$iface" -s -o /dev/null -A "$user_agent" -w "${label}status: %{http_code}\tbytes: %{size_download}\ttime: %{time_total}\n" "$url"
}

do_quiet_request() {
        local iface="$1"
        local user_agent path url

        user_agent="$(pick_random_line "$UA_FILE")"
        path="$(pick_random_line "$URL_FILE")"
        url="http://${VS_ADDR}${path}"

        curl "$CURL_HTTP_VERSION_FLAG" --interface "$iface" -s -o /dev/null -A "$user_agent" "$url"
}

run_request_triplet() {
        local iface="$1"
        local label="$2"

        do_report_request "$iface" "$label"
        do_quiet_request "$iface"
        do_quiet_request "$iface"
}

on_interrupt() {
        echo
        echo "Stopping current baseline mode"
        stop_flag=1
}

run_increasing_mode() {
        local minute i

        stop_flag=0
        while [[ "$stop_flag" -eq 0 ]]; do
                clear
                echo "Hourly increasing traffic: $VS_ADDR"
                echo

                minute=$((10#$(date +%M)))
                for ((i = 0; i <= minute && stop_flag == 0; i++)); do
                        run_request_triplet "$INCREASING_IFACE" ""
                done
        done
}

run_alternate_mode() {
        local hour request_count iface label i

        stop_flag=0
        while [[ "$stop_flag" -eq 0 ]]; do
                clear
                echo "Hourly alternate traffic: $VS_ADDR"
                echo

                hour=$((10#$(date +%H)))
                if ((hour % 2)); then
                        request_count=100
                        iface="$ALT_HIGH_IFACE"
                        label="High:\t"
                else
                        request_count=50
                        iface="$ALT_LOW_IFACE"
                        label="Low:\t"
                fi

                for ((i = 1; i <= request_count && stop_flag == 0; i++)); do
                        run_request_triplet "$iface" "$label"
                done
        done
}

require_binary curl
require_binary shuf
require_file "$UA_FILE"
require_file "$URL_FILE"
validate_addresses

trap on_interrupt INT TERM

clear
echo "Traffic Baselining"
echo

PS3='Please enter your type of baselining: '
options=("increasing" "alternate" "Quit")
select opt in "${options[@]}"
do
        case "$opt" in
                "increasing")
                        run_increasing_mode
                        ;;
                "alternate")
                        run_alternate_mode
                        ;;
                "Quit")
                        break
                        ;;
                *)
                        echo "invalid option"
                        ;;
        esac
done
