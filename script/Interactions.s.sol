// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator, account);

        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrdCoordinator, address account) public returns (uint256, address) {
        console.log("Creating Subscription on chainId", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrdCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created with id", subId);

        return (subId, vrdCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {
        console.log("Funding subscription on chainId", block.chainid);
        console.log("Using vrfCoordinator", vrfCoordinator);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }   

    function run() public {
        fundSubscriptionUsingConfig();
    }

    
}

contract AddConsumer is Script {
        function run() public {
            address mostRecentContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
            addConsumerUsingConfig(mostRecentContract);
        }

        function addConsumerUsingConfig(address mostRecentContract) public {
            HelperConfig helperConfig = new HelperConfig();
            uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
            address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
            address account = helperConfig.getConfig().account;
            addConsumer(mostRecentContract , vrfCoordinator, subscriptionId, account);
        }

        function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subscriptionId, address account) public {
            console.log("Adding consumer contract", contractToAddToVrf);
            console.log("To vrfCoordinator", vrfCoordinator);
            console.log("on chainId", block.chainid);

            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, contractToAddToVrf);
            vm.stopBroadcast();
        }
    }