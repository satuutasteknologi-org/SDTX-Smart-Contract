#!/bin/bash
ADDRESS="0x11e31b28757BC784b1F388A1931173Db3d081f83"
PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ADDRESS\", \"latest\"],\"id\":1}"

check_rpc() {
  local NAME=$1
  local URL=$2
  local RES=$(curl -s -X POST -H "Content-Type: application/json" --data "$PAYLOAD" --max-time 5 "$URL")
  local BAL=$(echo "$RES" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
  if [ ! -z "$BAL" ] && [ "$BAL" != "0x0" ]; then
    # Convert hex to decimal
    local DEC=$(printf "%d\n" "$BAL")
    echo "$NAME: HAS BALANCE ($DEC wei)"
  else
    echo "$NAME: 0"
  fi
}

echo "Checking Native Balances..."
check_rpc "Ethereum Mainnet" "https://rpc.ankr.com/eth"
check_rpc "Base Mainnet" "https://mainnet.base.org"
check_rpc "BSC Mainnet" "https://bsc-dataseed.binance.org/"
check_rpc "Arbitrum" "https://arb1.arbitrum.io/rpc"
check_rpc "Optimism" "https://mainnet.optimism.io"
check_rpc "Polygon" "https://polygon-rpc.com"
check_rpc "Ethereum Sepolia (Testnet)" "https://rpc2.sepolia.org"
check_rpc "Ethereum Holesky (Testnet)" "https://ethereum-holesky-rpc.publicnode.com"
check_rpc "Base Sepolia (Testnet)" "https://sepolia.base.org"

# Check ERC-20 ETH on BSC
ERC20_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"0x2170Ed0880ac9A755fd29B2688956BD959F933F8\",\"data\":\"0x70a0823100000000000000000000000011e31b28757bc784b1f388a1931173db3d081f83\"}, \"latest\"],\"id\":1}"
RES=$(curl -s -X POST -H "Content-Type: application/json" --data "$ERC20_PAYLOAD" --max-time 5 "https://bsc-dataseed.binance.org/")
BAL=$(echo "$RES" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
if [ ! -z "$BAL" ] && [ "$BAL" != "0x0" ] && [ "$BAL" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
  echo "BSC Mainnet (Binance-Peg ETH ERC20): HAS BALANCE"
else
  echo "BSC Mainnet (Binance-Peg ETH ERC20): 0"
fi
