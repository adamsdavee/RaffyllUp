// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./CommunityRaffyll.sol";


// contract RaffylFactory {

//     event CommunityCreated(address indexed admin, address communityAddress, string name, string ens);

//     address[] public communities;
//     mapping(address => address[]) public adminToCommunities;

//     function createCommunity(address admin, string calldata name, string calldata ens) external returns (address) {

//         require(adminToCommunities[admin] == address[](0), "User has community");

//         CommunityRaffyll community = new CommunityRaffyll(admin, name, ens, address(this));
//         communities.push(address(community));
//         adminToCommunities[admin].push(address(community));
//         emit CommunityCreated(admin, address(community), name, ens);
//         return address(community);
//     }

//     function getCommunities() external view returns (address[] memory) {
//         return communities;
//     }
// }