// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SatuutaS Delta Tech X (SDTX)
 * @dev Enterprise-grade, immutable utility token for PT. Satuutas Delta Teknologi.
 * 
 * SECURITY & ANTI-FRAUD FEATURES:
 * 1. Hardcapped Supply: No mint() function exists. Supply can never be inflated.
 * 2. Ownable2Step: Prevents accidental loss of contract ownership.
 * 3. Native Token Lock: recoverLostTokens() explicitly forbids owner from touching SDTX tokens 
 *    that end up in this contract, eliminating rug-pull vectors.
 * 4. Custom Errors: Modern Gas-Optimized error handling.
 */
contract SDTX is ERC20, ERC20Burnable, ERC20Permit, Ownable2Step {
    
    // Custom errors for gas optimization and advanced security tracking
    error CannotRecoverNativeToken();
    error ZeroAddressProvided();

    // Total Fixed Supply: 800 Million Tokens
    uint256 public constant TOTAL_SUPPLY = 800_000_000 * 10 ** 18;

    /**
     * @dev Constructor mints the entire fixed supply to the deployer's address.
     * The supply is mathematically hardcoded and cannot ever be increased (Immutable).
     */
    constructor(address initialOwner) 
        ERC20("SatuutaS Delta Tech X", "SDTX") 
        ERC20Permit("SatuutaS Delta Tech X") 
        Ownable(initialOwner) 
    {
        if (initialOwner == address(0)) {
            revert ZeroAddressProvided();
        }
        _mint(initialOwner, TOTAL_SUPPLY);
    }

    /**
     * @dev Emergency recovery function. In case other ERC20 tokens are accidentally 
     * sent to this contract address, the owner can recover them.
     * @param _token The address of the token to recover.
     * @param _to The address to send the recovered tokens to.
     * @param _amount The amount of tokens to recover.
     */
    function recoverLostTokens(address _token, address _to, uint256 _amount) external onlyOwner {
        // ANTI-FRAUD: Owner cannot pull SDTX from this contract.
        if (_token == address(this)) {
            revert CannotRecoverNativeToken();
        }
        // SECURITY: Prevent burning tokens by sending to address(0) accidentally.
        if (_to == address(0)) {
            revert ZeroAddressProvided();
        }
        IERC20(_token).transfer(_to, _amount);
    }
}
