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
        uint256 baseCollateral = 10 gwei; // Deposit 10 WETH each
        uint256 gasMoney = 0.05 gwei; // ETH for gas fees on Sepolia

        console.log("Populating", _numberOfUsers, "users...");

        address[] memory users = new address[](_numberOfUsers);
        uint256[] memory pks = new uint256[](_numberOfUsers);

        // PRE-CALCULATE ADDRESSES
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            pks[i] = vm.deriveKey(MNEMONIC, i);
            users[i] = vm.addr(pks[i]);
        }

        // PHASE 1: MASS FUNDING (One broadcast from your --account)
        console.log("Phase 1: Funding users from Bank...");
        vm.startBroadcast();
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            (bool success,) = users[i].call{value: gasMoney}("");
            require(success, "ETH transfer failed. Check main account ETH balance.");
            IERC20(weth).transfer(users[i], baseCollateral);
        }
        vm.stopBroadcast();

        // PHASE 2: INDIVIDUAL DEPOSITS
        console.log("Phase 2: Users depositing to Engine...");
        for (uint32 i = 0; i < _numberOfUsers; i++) {
            uint256 bucket = vm.randomUint(0, 3);
            uint256 dscToMint = _getMintAmount(bucket);

            vm.startBroadcast(pks[i]);
            IERC20(weth).approve(address(engine), baseCollateral);
            engine.depositCollateralAndMintDsc(weth, baseCollateral, dscToMint);
            vm.stopBroadcast();

            console.log("User", i, "deposited in bucket:", bucket);
        }

        console.log("Successfully populated users!");
    }

    function _getMintAmount(uint256 bucket) internal pure returns (uint256) {
        if (bucket == 0) return 1000 gwei; // HF > 2
        if (bucket == 1) return 6000 gwei; // 1.5 - 2
        if (bucket == 2) return 7500 gwei; // 1.2 - 1.5
        return 9000 gwei; // 1.0 - 1.2
    }
}
