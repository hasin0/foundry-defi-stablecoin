// SPDX-License-Identifier: MIT

// what are our invariant properties?
// 1. the total supply of the token(dsc) should be less dan total value of collateral or equal to the sum of all balances
//2 getter view  functions should return the same value as the state variables or revert

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();

        handler = new Handler(dsce, dsc);
        targetContract(address(handler));

        // targetContract(address(dsce));
    }

    function invariant_ProtocolTotalSupplyLessThanCollateralValue() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("totalSupply: ", totalSupply);
        console.log("wethValue: ", wethValue);
        console.log("wbtcValue: ", wbtcValue);
        console.log("Times Mint Called: ", handler.timesMintCalled());

        assert(totalSupply <= wethValue + wbtcValue);
    }

    // function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
    //     //get values of all collateral in the protocol
    //     // compare  to all the debt(dsc) in the protocol
    //     uint256 totalSupply = dsc.totalSupply();
    //     uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
    //     uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));
    //     console.log("totalSupply: ", totalSupply);
    //     console.log("totalWethDeposited: ", totalWethDeposited);
    //     console.log("totalWbtcDeposited: ", totalWbtcDeposited);
    //     console.log("Times Mint Called: ", handler.timesMintCalled());

    //     uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
    //     uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

    //     assert(wethValue + wbtcValue >= totalSupply);
    // }
}
