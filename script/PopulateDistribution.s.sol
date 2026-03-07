// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PopulateDistribution is Script {
    DSCEngine engine;
    HelperConfig config;
    address weth;

    // Standard Forge test mnemonic - safe to use publicly for dummy accounts
    string constant MNEMONIC = "test test test test test test test test test test test junk";

    function run(address _engineAddress, address _helperConfigAddress, uint32 _numberOfUsers) external {
        engine = DSCEngine(_engineAddress);
        config = HelperConfig(_helperConfigAddress);

        (,, weth,) = config.activeNetworkConfig();

        console.log("WETH Address: ", weth);

        // Constants for funding
        uint256 baseCollateral = 10 ether; // Deposit 10 WETH each
        uint256 gasMoney = 0.05 ether; // ETH for gas fees on Sepolia

        console.log("Populating", _numberOfUsers, "users...");

        for (uint32 i = 0; i < _numberOfUsers; i++) {
            // 1. Generate user wallet from mnemonic
            uint256 userPk = vm.deriveKey(MNEMONIC, i);
            address user = vm.addr(userPk);
            console.log("--- Setting up User:", user, "---");

            // 2. Fund the user with ETH and WETH from your main account
            // Calling vm.startBroadcast() without args uses the account from the CLI
            vm.startBroadcast();

            // Send native ETH for gas (required for Sepolia)
            (bool success,) = user.call{value: gasMoney}("");
            require(success, "ETH transfer failed. Check main account ETH balance.");

            // Send WETH
            IERC20(weth).transfer(user, baseCollateral);
            vm.stopBroadcast();

            // 3. Determine how much DSC to mint based on bucket (0 to 3)
            uint256 bucket = vm.randomUint(0, 3); // inclusive on both ends
            uint256 dscToMint;

            if (bucket == 0) {
                dscToMint = 1000 ether; // HF > 2.0
                console.log("Target: HF > 2.0");
            } else if (bucket == 1) {
                dscToMint = 6000 ether; // 1.5 < HF < 2.0
                console.log("Target: 1.5 < HF < 2.0");
            } else if (bucket == 2) {
                dscToMint = 7500 ether; // 1.2 < HF < 1.5
                console.log("Target: 1.2 < HF < 1.5");
            } else {
                dscToMint = 9000 ether; // 1.0 < HF < 1.2
                console.log("Target: 1.0 < HF < 1.2");
            }

            // 4. Act as the dummy user to approve and mint
            vm.startBroadcast(userPk);
            IERC20(weth).approve(address(engine), baseCollateral);
            engine.depositCollateralAndMintDsc(weth, baseCollateral, dscToMint);
            vm.stopBroadcast();
        }

        console.log("Successfully populated users!");
    }
}
