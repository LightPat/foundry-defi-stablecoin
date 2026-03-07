// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        vm.startBroadcast();
        HelperConfig helperConfig = new HelperConfig();
        helperConfig.deployMocksAndSetConfig();
        vm.stopBroadcast();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc) =
            helperConfig.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        console.log("WETH Price Feed:", wethUsdPriceFeed);
        console.log("WBTC Price Feed:", wbtcUsdPriceFeed);
        console.log("WETH:", weth);
        console.log("WBTC:", wbtc);

        return (dsc, dscEngine, helperConfig);
    }
}
