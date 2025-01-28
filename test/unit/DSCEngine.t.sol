// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address weth;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);

        // // Mint a very large amount of WETH to the USER
        // ERC20Mock(weth).mint(USER, 1000000 ether);

        // // Approve the DSCEngine to spend WETH on behalf of the USER
        // ERC20Mock(weth).approve(address(dsce), type(uint256).max);

        // // Verify the allowance
        // require(ERC20Mock(weth).allowance(USER, address(dsce)) == type(uint256).max, "Insufficient allowance");

        // // Verify the balance
        // require(ERC20Mock(weth).balanceOf(USER) >= 1000000 ether, "Insufficient WETH balance");
    }

    /////////////////
    // constructor Tests //
    /////////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /////////////////
    // Price Tests //
    /////////////////

    function testGetUsdValue() public view {
        // 15e18 * 2,000/ETH = 30,000e18
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testgetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        console.log(usdAmount);

        // 100e18 / 2000 = 0.05e18 or 0.05 ether
        uint256 expectedWeth = 0.05 ether;
        console.log(expectedWeth);
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        console.log(actualWeth);
        assertEq(expectedWeth, actualWeth);
    }

    // function testGetUsdValue() public view {
    //     uint256 ethAmount = 15e18;
    //     console.log("working so far");
    //     uint256 expectedUsd = 30000e18;
    //     console.log("working so far");
    //     uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
    //     console.log("working so far");
    //     assert(expectedUsd == actualUsd);
    // }

    /////////////////////////////
    // depositCollateral Tests //
    /////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        console.log("starting test");
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        console.log("approved");

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        console.log("expecting revert");
        dsce.depositCollateral(weth, 0);
        console.log("deposited collateral");
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        console.log("created token");
        vm.startPrank(USER);
        console.log("prank started");
        // vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        // vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed(address(ranToken)));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(ranToken)));

        console.log("expecting revert");
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        console.log("deposited collateral");
        vm.stopPrank();
        console.log("prank stopped");
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        console.log(totalDscMinted, collateralValueInUsd);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        console.log(expectedTotalDscMinted, expectedDepositAmount);
        // console.log(expectedTotalDscMinted, expectedCollateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        console.log("asserted totalDscMinted");
        // console.log("asserted totalDscMinted");
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
        console.log("asserted collateralValueInUsd");

        //dsce.getAccountInfo(weth, address(this));
    }

    // function testCanDepositedCollateralAndGetAccountInfo() public depositedCollateral {
    //     (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
    //     uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
    //     assertEq(totalDscMinted, 0);
    //     assertEq(expectedDepositedAmount, AMOUNT_COLLATERAL);
    // }
}
