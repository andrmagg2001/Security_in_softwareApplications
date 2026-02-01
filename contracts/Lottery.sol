pragma solidity ^0.8.22;

import "./Taxpayer.sol";

contract Lottery {
    mapping(address => bytes32) internal commits;
    mapping(address => uint256) internal reveals;
    mapping(address => bool) internal hasCommitted;
    mapping(address => bool) internal hasRevealed;
    address[] internal revealed;

    uint256 internal startTime;
    uint256 internal revealTime;
    uint256 internal endTime;
    uint256 internal period;

    bool internal iscontract;

    constructor(uint256 p) {
        period = p;
        iscontract = true;
    }

    function startLottery() public {
        require(startTime == 0, "already started");
        startTime = block.timestamp;
        revealTime = startTime + period;
        endTime = revealTime + period;
    }

    function commit(bytes32 y) public {
        require(startTime != 0, "not started");
        require(block.timestamp >= startTime && block.timestamp < revealTime, "commit phase");
        require(!hasCommitted[msg.sender], "already committed");
        require(y != bytes32(0), "bad commit");

        commits[msg.sender] = y;
        hasCommitted[msg.sender] = true;
    }

    function reveal(uint256 rev) public {
        require(startTime != 0, "not started");
        require(block.timestamp >= revealTime && block.timestamp < endTime, "reveal phase");
        require(hasCommitted[msg.sender], "no commit");
        require(!hasRevealed[msg.sender], "already revealed");
        require(keccak256(abi.encode(rev)) == commits[msg.sender], "bad reveal");

        hasRevealed[msg.sender] = true;
        reveals[msg.sender] = rev;
        revealed.push(msg.sender);
    }

    function endLottery() public {
        require(startTime != 0, "not started");
        require(block.timestamp >= endTime, "too early");
        require(revealed.length > 0, "no reveals");

        uint256 total = 0;
        for (uint256 i = 0; i < revealed.length; i++) {
            total += reveals[revealed[i]];
        }

        Taxpayer(revealed[total % revealed.length]).setTaxAllowance(7000);

        for (uint256 i = 0; i < revealed.length; i++) {
            address a = revealed[i];
            commits[a] = bytes32(0);
            reveals[a] = 0;
            hasCommitted[a] = false;
            hasRevealed[a] = false;
        }

        delete revealed;

        startTime = 0;
        revealTime = 0;
        endTime = 0;
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }
}