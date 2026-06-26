import { ethers } from "ethers";
import fs from "fs";
import * as dotenv from "dotenv";
dotenv.config();

// Membaca file hasil kompilasi Smart Contract
const contractJson = JSON.parse(fs.readFileSync("./artifacts/contracts/SDTXToken.sol/SDTX.json", "utf8"));

async function main() {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
      throw new Error("Private Key tidak ditemukan di dalam file .env!");
  }

  // Koneksi ke Base Mainnet (Uang Asli)
  const rpcUrl = process.env.BASE_MAINNET_RPC || "https://mainnet.base.org";
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  
  // Membuat objek wallet dari Private Key
  const deployer = new ethers.Wallet(privateKey, provider);

  console.log("==========================================");
  console.log("Memulai Peluncuran $SDTX Token...");
  console.log("Alamat Wallet Deployer:", deployer.address);

  // Cek Saldo ETH
  const balance = await provider.getBalance(deployer.address);
  console.log("Saldo ETH Saat Ini:", ethers.formatEther(balance), "ETH");

  if (balance === 0n) {
      throw new Error("Saldo ETH Anda 0! Harap isi dari Faucet terlebih dahulu (atau deposit dari Exchange).");
  }

  // Menyiapkan peluncuran kontrak
  const SDTXTokenFactory = new ethers.ContractFactory(contractJson.abi, contractJson.bytecode, deployer);
  
  console.log("Mengeksekusi transaksi ke Blockchain Base Mainnet...");
  // Meluncurkan kontrak dan mengirimkan address wallet sebagai parameter initialOwner
  const sdtx = await SDTXTokenFactory.deploy(deployer.address);

  console.log("Menunggu konfirmasi jaringan...");
  await sdtx.waitForDeployment();
  const contractAddress = await sdtx.getAddress();

  console.log("==========================================");
  console.log("🚀 $SDTX Token BERHASIL DILUNCURKAN!");
  console.log("📡 Jaringan: Base Mainnet (Real World)");
  console.log("📄 Contract Address:", contractAddress);
  console.log("==========================================");
}

main().catch((error) => {
  console.error("\n❌ TERJADI KESALAHAN:");
  console.error(error.message || error);
  process.exitCode = 1;
});
