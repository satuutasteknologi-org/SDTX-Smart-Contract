import { ethers } from "ethers";
import fs from "fs";

// Membaca file hasil kompilasi Smart Contract
const contractJson = JSON.parse(fs.readFileSync("./artifacts/contracts/NadiToken.sol/Nadi.json", "utf8"));

async function main() {
  // Ini adalah Private Key bawaan Hardhat (Akun 0) yang otomatis berisi 10.000 ETH Palsu lokal
  const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  
  // Koneksi ke Local Node (Server di laptop/mesin sendiri)
  const rpcUrl = "http://127.0.0.1:8545";
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  
  // Membuat objek wallet dari Private Key
  const deployer = new ethers.Wallet(privateKey, provider);

  console.log("==========================================");
  console.log("Memulai Peluncuran LOKAL/INTERNAL $NADI Token...");
  console.log("Alamat Wallet Simulasi:", deployer.address);

  // Cek Saldo ETH (Pasti 10.000 ETH)
  const balance = await provider.getBalance(deployer.address);
  console.log("Saldo ETH Simulasi Saat Ini:", ethers.formatEther(balance), "ETH");

  // Menyiapkan peluncuran kontrak
  const NadiTokenFactory = new ethers.ContractFactory(contractJson.abi, contractJson.bytecode, deployer);
  
  console.log("Mengeksekusi transaksi ke Blockchain Internal...");
  // Meluncurkan kontrak dan mengirimkan address wallet sebagai parameter initialOwner
  const nadi = await NadiTokenFactory.deploy(deployer.address);

  console.log("Menunggu konfirmasi blok lokal...");
  await nadi.waitForDeployment();
  const contractAddress = await nadi.getAddress();

  console.log("==========================================");
  console.log("🚀 $NADI Token BERHASIL DILUNCURKAN SECARA LOKAL!");
  console.log("📡 Jaringan: Hardhat Internal (127.0.0.1)");
  console.log("📄 Contract Address:", contractAddress);
  console.log("==========================================");
}

main().catch((error) => {
  console.error("\n❌ TERJADI KESALAHAN LOKAL:");
  console.error(error.message || error);
  process.exitCode = 1;
});
