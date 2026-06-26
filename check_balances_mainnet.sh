#!/bin/bash
ADDRESS="0x11e31b28757BC784b1F388A1931173Db3d081f83"
PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ADDRESS\", \"latest\"],\"id\":1}"

check_rpc() {
  local NAME=$1
  local URL=$2
  local RES=$(curl -s -X POST -H "Content-Type: application/json" --data "$PAYLOAD" --max-time 5 "$URL")
  local BAL=$(echo "$RES" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
  if [ ! -z "$BAL" ] && [ "$BAL" != "0x0" ]; then
    local DEC=$(printf "%d\n" "$BAL")
    echo "$NAME: HAS BALANCE ($DEC wei)"
  else
    echo "$NAME: 0"
  fi
}

echo "Checking Native Balances for $ADDRESS..."
check_rpc "Ethereum Mainnet" "https://rpc.ankr.com/eth"
check_rpc "Base Mainnet" "https://mainnet.base.org"
check_rpc "BSC Mainnet" "https://bsc-dataseed.binance.org/"
