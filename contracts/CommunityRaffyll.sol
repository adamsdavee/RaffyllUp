// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { RaffylRaffle } from "./RaffylRaffle.sol";

contract CommunityRaffyll is ReentrancyGuard {
    using Address for address;

    event RaffleCreated(address indexed raffleAddress, uint256 indexed raffleId, string name);

    address public admin;
    address public factory;
    string public communityName;
    string public ensName;
    address[] public raffles;

    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not community admin");
        _;
    }

    constructor(address _admin, string memory name, string memory ens, address _factory) {
        isAdmin[_admin] = true;
        communityName = name;
        ensName = ens;
        factory = _factory;
    }

    function createRaffle(
        string calldata raffleName,
        address prizeToken,
        uint256 numOfWinners,
        uint256 startTime,
        uint256 endTime
    ) external onlyAdmin returns (address) {
        require(startTime < endTime, "start must be before end");

        RaffylRaffle raffle = new RaffylRaffle(
            address(this),
            msg.sender,
            raffleName,
            prizeToken,
            numOfWinners,
            startTime,
            endTime
        );

        raffles.push(address(raffle));
        emit RaffleCreated(address(raffle), raffles.length - 1, raffleName);
        return address(raffle);
    }

    function makeCommunityAdmin(address newAdmin) external onlyAdmin {
        isAdmin[newAdmin] = true;
    }

    function getRaffles() external view returns (address[] memory) {
        return raffles;
    }
}