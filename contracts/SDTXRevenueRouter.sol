// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SDTX Enterprise Revenue Router (The Conservation Engine)
 * @dev Menerima pembayaran SaaS B2B, memotong 15% untuk otomatis membeli $SDTX di DEX, 
 * lalu membakarnya (Burn) secara permanen untuk memicu Kelangkaan (Scarcity).
 * Sisanya dikirim ke Kas Perusahaan (Treasury).
 */

// 1. Interface untuk SDTX Token (Agar Router bisa memanggil fungsi burn)
interface ISDTX is IERC20 {
    function burn(uint256 amount) external;
}

// 2. Interface untuk Bursa Desentralisasi (Uniswap V3 / Aerodrome di Base Network)
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract SDTXRevenueRouter is Ownable2Step {
    // Alamat Kontrak Penting di Jaringan Base Mainnet
    IERC20 public usdc;
    ISDTX public sdtx;
    ISwapRouter public dexRouter;
    
    address public treasuryWallet; // Dompet Kas Perusahaan SatuutaS

    // Metrik Ekonomi
    uint256 public burnPercentage = 15; // 15% dari pendapatan SaaS akan dibakar
    uint256 public totalSdtxBurned;     // Melacak total SDTX yang berhasil dimusnahkan Router

    event RevenueProcessed(uint256 totalUsdc, uint256 usdcToTreasury, uint256 sdtxBurned);
    event BurnPercentageUpdated(uint256 oldPercentage, uint256 newPercentage);

    constructor(
        address _usdc,
        address _sdtx,
        address _dexRouter,
        address _treasuryWallet,
        address initialOwner
    ) Ownable(initialOwner) {
        usdc = IERC20(_usdc);
        sdtx = ISDTX(_sdtx);
        dexRouter = ISwapRouter(_dexRouter);
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @dev Fungsi Utama (The Engine): Dipanggil saat klien migas membayar tagihan *software*.
     * @param usdcAmount Jumlah USDC yang dibayarkan klien (dalam satuan Wei).
     */
    function processSaaSRevenue(uint256 usdcAmount) external {
        require(usdcAmount > 0, "SDTXRouter: Payment must be greater than zero");

        // 1. Tarik USDC dari dompet Klien ke dalam Router ini
        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "SDTXRouter: Transfer failed");

        // 2. Hitung Matematika Pembagian
        uint256 usdcForBurn = (usdcAmount * burnPercentage) / 100;
        uint256 usdcForTreasury = usdcAmount - usdcForBurn;

        // 3. Kirim Profit 85% ke Kas Perusahaan SatuutaS
        require(usdc.transfer(treasuryWallet, usdcForTreasury), "SDTXRouter: Treasury transfer failed");

        // 4. Eksekusi "Conservation Burn" Otomatis menggunakan sisa 15% USDC
        uint256 sdtxBought = _swapUsdcForSdtx(usdcForBurn);
        
        // 5. Bakar SDTX yang baru saja dibeli! (Deflasi)
        sdtx.burn(sdtxBought);
        
        // 6. Catat sejarah untuk audit publik
        totalSdtxBurned += sdtxBought;
        emit RevenueProcessed(usdcAmount, usdcForTreasury, sdtxBought);
    }

    /**
     * @dev Fungsi Internal: Berkomunikasi dengan Bursa Publik untuk menukar USDC menjadi SDTX
     */
    function _swapUsdcForSdtx(uint256 amountIn) internal returns (uint256) {
        // Beri izin kepada DEX untuk mengambil USDC dari Router ini
        usdc.approve(address(dexRouter), amountIn);

        // Parameter pertukaran (Swap) Uniswap V3
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(usdc),
            tokenOut: address(sdtx),
            fee: 3000, // Fee bursa (0.3%)
            recipient: address(this), // SDTX masuk ke Router ini
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0, // Minimal SDTX yang diterima (Bisa diatur dengan slippage protection)
            sqrtPriceLimitX96: 0
        });

        // Eksekusi pembelian di Pasar Terbuka
        uint256 amountOut = dexRouter.exactInputSingle(params);
        return amountOut;
    }

    /**
     * @dev Tata Kelola: Mengizinkan pemegang saham (Owner/veSDTX) mengubah rasio bakar.
     */
    function setBurnPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "SDTXRouter: Invalid percentage");
        emit BurnPercentageUpdated(burnPercentage, _newPercentage);
        burnPercentage = _newPercentage;
    }

    /**
     * @dev Tata Kelola: Mengubah alamat Kas Perusahaan.
     */
    function setTreasuryWallet(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "SDTXRouter: Invalid address");
        treasuryWallet = _newTreasury;
    }
}
