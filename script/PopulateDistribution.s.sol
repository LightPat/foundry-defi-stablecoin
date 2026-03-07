// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PopulateDistribution is Script {
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;

    // string constant MNEMONIC = "test test test test test test test test test test test junk";
    string constant MNEMONIC = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

    function run(address _engineAddress, address _dscAddress, address _helperConfigAddress, uint32 _numberOfUsers)
        external
    {
        engine = DSCEngine(_engineAddress);
        dsc = DecentralizedStableCoin(_dscAddress);
        config = HelperConfig(_helperConfigAddress);

        (,, weth,) = config.activeNetworkConfig();

        console.log("WETH Address: ", weth);

        uint256 startNativeETH = msg.sender.balance;
        uint256 startWETH = IERC20(weth).balanceOf(msg.sender);

        console.log("=== STARTING BALANCES ===");
        console.log("Sepolia ETH (wei):", startNativeETH);
        console.log("WETH balance (wei):", startWETH);
        // Also log gas price for context
        console.log("Current tx gas price (wei):", tx.gasprice);
        console.log();

        // Constants for funding
        uint256 baseCollateral = 10 gwei; // Deposit 10 WETH each
        uint256 gasMoney = 0.009 ether; // ETH for gas fees on Sepolia

        console.log("Populating", _numberOfUsers, "users...");

        address[] memory users = new address[](_numberOfUsers);
        uint256[] memory pks = new uint256[](_numberOfUsers);

        // PRE-CALCULATE ADDRESSES
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            pks[i] = vm.deriveKey(MNEMONIC, i + 1327819);
            users[i] = vm.addr(pks[i]);
        }

        // PHASE 1: MASS FUNDING (One broadcast from your --account)
        console.log("Phase 1: Funding users from Bank...");
        vm.startBroadcast();
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            uint256 userDscBalance = dsc.balanceOf(users[i]);
            uint256 userNative = users[i].balance;
            uint256 userWETH = IERC20(weth).balanceOf(users[i]);

            if (userDscBalance > 0) {
                // If dsc is already minted at this address, send any remaining eth and weth back to us
                // Need to add approval steps and other stuff to make this work

                // if (userWETH > 0) {
                //     bool success = IERC20(weth).transfer(users[i], userWETH);
                //     require(success, "Returning WETH transfer failed.");
                // }

                // if (userNative > 0) {
                //     (bool success,) = msg.sender.call{value: userNative}("");
                //     require(success, "Returning ETH transfer failed.");
                // }
            } else {
                // No dsc at this address yet
                if (userNative < gasMoney) {
                    (bool success,) = users[i].call{value: gasMoney - userNative}("");
                    require(success, "ETH transfer failed. Check main account ETH balance.");
                }

                if (userWETH < baseCollateral) {
                    bool success = IERC20(weth).transfer(users[i], baseCollateral - userWETH);
                    require(success, "WETH transfer failed. Check main account WETH balance.");
                }
            }
        }
        vm.stopBroadcast();

        // PHASE 2: INDIVIDUAL DEPOSITS
        console.log("Phase 2: Users depositing to Engine...");
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            uint256 userDscBalance = dsc.balanceOf(users[i]);

            if (userDscBalance > 0) {
                continue;
            }

            uint256 bucket = vm.randomUint(0, 3);
            uint256 dscToMint = _getMintAmount(bucket);

            vm.startBroadcast(pks[i]);
            IERC20(weth).approve(address(engine), baseCollateral);
            engine.depositCollateralAndMintDsc(weth, baseCollateral, dscToMint);
            vm.stopBroadcast();

            console.log("User", i, "bucket:", bucket);
            console.log(users[i]);
        }

        console.log("Successfully populated users!");
        console.log();

        // ────────────────────────────────────────────────────────────────
        //    BALANCE LOGGING - END + COST CALCULATION
        // ────────────────────────────────────────────────────────────────
        uint256 endNativeETH = msg.sender.balance;
        uint256 endWETH = IERC20(weth).balanceOf(msg.sender);

        uint256 spentNativeETH = startNativeETH - endNativeETH;
        uint256 spentWETH = startWETH - endWETH;

        console.log("=== ENDING BALANCES ===");
        console.log("Native Sepolia ETH (wei):", endNativeETH);
        console.log("WETH balance (wei):", endWETH);

        console.log("=== ACTUAL COST OF THE RUN ===");
        console.log("Spent native ETH (wei):", spentNativeETH);
        console.log("Locked in protocol (WETH spent - wei):", spentWETH);
    }

    function _getMintAmount(uint256 bucket) internal pure returns (uint256) {
        if (bucket == 0) return 1000 gwei; // HF > 2
        if (bucket == 1) return 6000 gwei; // 1.5 - 2
        if (bucket == 2) return 7500 gwei; // 1.2 - 1.5
        return 9000 gwei; // 1.0 - 1.2
    }
}
