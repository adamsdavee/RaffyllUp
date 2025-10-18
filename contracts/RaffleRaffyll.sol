// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RaffylRaffle is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event ParticipantRegistered(address indexed participant);
    event WinnersSelected(address[] winners); // in selection order (first selected -> third place)
    event PrizeFunded(address token, uint256 amount);
    event PrizeDistributed(address token, uint256 total, uint256 winnersCount);

    address public community;
    address public admin; // community admin who can trigger selection
    string public raffleName;

    address public prizeToken; // address(0) for native
    uint256 public numWinners; // fixed to 3 in this version

    uint256 public startTime;
    uint256 public endTime;

    address[] public participants;
    mapping(address => bool) public registered;

    address[] public winners;
    bool public winnersSelected;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _community,
        address _admin,
        string memory _raffleName,
        address _prizeToken,
        uint256 _numWinners,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_startTime < _endTime, "Invalid times");
        require(_numWinners == 3, "Only 3 winners supported");
        community = _community;
        admin = _admin;
        raffleName = _raffleName;
        prizeToken = _prizeToken;
        numWinners = _numWinners;
        startTime = _startTime;
        endTime = _endTime;
    }


    // Fund ERC20 prize (only allowed token must match prizeToken when prizeToken != address(0))
    function fundPrizeERC20(uint256 amount) external {
        require(prizeToken != address(0), "This raffle accepts native only");
        IERC20(prizeToken).safeTransferFrom(msg.sender, address(this), amount);
        emit PrizeFunded(prizeToken, amount);
    }

    // Fund native prize
    function fundPrizeNative() external payable {
        require(prizeToken == address(0), "This raffle accepts ERC20 only");
        require(msg.value > 0, "Must send funds");
        emit PrizeFunded(address(0), msg.value);
    }


    // Participant registers on-chain (gas paid by participant). Prevent duplicates.
    function register(address participant) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Registration closed");
        require(!registered[participant], "Already registered");
        registered[participant] = true;
        participants.push(participant);
        emit ParticipantRegistered(participant);
    }


    // Admin triggers winner selection after raffle end.
    // Selection order: first selected -> third place (20%), second -> second place (30%), third -> first place (50%)
    function selectWinners() external onlyAdmin nonReentrant {
        require(block.timestamp > endTime, "Raffle not ended");
        require(!winnersSelected, "Already selected");
        uint256 partCount = participants.length;
        require(partCount > 0, "No participants");

        uint256 winnersToPick = numWinners;
        if (partCount < winnersToPick) winnersToPick = partCount;

        // pick unique winners
        uint256 attempts = 0;
        uint256 i = 0;
        while (i < winnersToPick && attempts < partCount * 5) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, address(this), i, attempts)));
            address candidate = participants[rand % partCount];
            if (!_isWinner(candidate)) {
                winners.push(candidate);
                i++;
            }
            attempts++;
        }

        winnersSelected = true;
        emit WinnersSelected(winners);

        _distributePrize();
    }

    function _isWinner(address candidate) internal view returns (bool) {
        for (uint i = 0; i < winners.length; i++) if (winners[i] == candidate) return true;
        return false;
    }

    function _distributePrize() internal nonReentrant {
        uint256 count = winners.length;
        if (count == 0) return;

        
        // selection order [0] => 3rd place (20%), [1] => 2nd place (30%), [2] => 1st place (50%)
        uint16[3] memory bps = [uint16(2000), uint16(3000), uint16(5000)]; // basis points (out of 10000)

        if (prizeToken == address(0)) {
            uint256 total = address(this).balance;
            for (uint i = 0; i < 3; i++) {
                uint256 share = (total * bps[i]) / 10000;
                if (share > 0) payable(winners[i]).transfer(share);
            }
            emit PrizeDistributed(address(0), total, 3);
        } else {
            uint256 total = IERC20(prizeToken).balanceOf(address(this));
            for (uint i = 0; i < 3; i++) {
                uint256 share = (total * bps[i]) / 10000;
                if (share > 0) IERC20(prizeToken).safeTransfer(winners[i], share);
            }
            emit PrizeDistributed(prizeToken, total, 3);
        }
    }


    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    function participantsCount() external view returns (uint256) {
        return participants.length;
    }

    function isRegistered(address who) external view returns (bool) {
        return registered[who];
    }
}