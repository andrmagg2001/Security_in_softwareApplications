// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";

contract Lottery {
    enum Phase {
        NotStarted,
        Commit,
        Reveal
    }

    mapping(address => bytes32) internal commits;
    mapping(address => uint256) internal reveals;
    mapping(address => bool) internal hasCommitted;
    mapping(address => bool) internal hasRevealed;

    address[] internal committed;
    address[] internal revealed;

    uint256 internal startTime;
    uint256 internal revealTime;
    uint256 internal endTime;
    uint256 internal period;

    bool internal iscontract;

    address public lastWinner;
    uint256 public lastRevealedLen;

    Phase internal phase;

    constructor(uint256 p) {
        period = p;
        iscontract = true;
        phase = Phase.NotStarted;
    }

    function _syncPhase() internal {
        if (phase == Phase.Commit && block.timestamp >= revealTime) {
            phase = Phase.Reveal;
        }
    }

    function startLottery() public {
        require(phase == Phase.NotStarted, "already started");
        startTime = block.timestamp;
        revealTime = startTime + period;
        endTime = revealTime + period;
        phase = Phase.Commit;
    }

    function commit(bytes32 y) public {
        _syncPhase();
        require(phase == Phase.Commit, "not commit phase");
        require(startTime != 0 && block.timestamp >= startTime, "not started");
        require(block.timestamp < revealTime, "commit closed");
        require(!hasCommitted[msg.sender], "double commit");
        require(y != bytes32(0), "zero commit");

        commits[msg.sender] = y;
        hasCommitted[msg.sender] = true;
        committed.push(msg.sender);
    }

    function reveal(uint256 rev) public {
        _syncPhase();
        require(phase == Phase.Reveal, "not reveal phase");
        require(block.timestamp >= revealTime, "too early");
        require(block.timestamp < endTime, "reveal closed");
        require(hasCommitted[msg.sender], "no commit");
        require(!hasRevealed[msg.sender], "double reveal");
        require(keccak256(abi.encode(rev)) == commits[msg.sender], "bad reveal");

        hasRevealed[msg.sender] = true;
        reveals[msg.sender] = rev;
        revealed.push(msg.sender);
    }

    function endLottery() public {
        _syncPhase();
        require(phase == Phase.Reveal, "not finalize phase");
        require(block.timestamp >= endTime, "too early");
        require(revealed.length > 0, "no reveals");

        uint256 total = 0;
        for (uint256 i = 0; i < revealed.length; i++) {
            total += reveals[revealed[i]];
        }

        address winner = revealed[total % revealed.length];
        lastWinner = winner;
        lastRevealedLen = revealed.length;

        Taxpayer(winner).setTaxAllowance(7000);

        for (uint256 i = 0; i < committed.length; i++) {
            address a = committed[i];
            delete commits[a];
            delete reveals[a];
            delete hasCommitted[a];
            delete hasRevealed[a];
        }

        delete committed;
        delete revealed;

        startTime = 0;
        revealTime = 0;
        endTime = 0;
        phase = Phase.NotStarted;
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getRevealTime() external view returns (uint256) {
        return revealTime;
    }

    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    function getPhase() external view returns (uint8) {
        return uint8(phase);
    }

    function getCommit(address a) external view returns (bytes32) {
        return commits[a];
    }

    function getReveal(address a) external view returns (uint256) {
        return reveals[a];
    }

    function getHasCommitted(address a) external view returns (bool) {
        return hasCommitted[a];
    }

    function getHasRevealed(address a) external view returns (bool) {
        return hasRevealed[a];
    }

    function getCommittedLen() external view returns (uint256) {
        return committed.length;
    }

    function getCommittedAt(uint256 i) external view returns (address) {
        return committed[i];
    }

    function getRevealedLen() external view returns (uint256) {
        return revealed.length;
    }

    function getRevealedAt(uint256 i) external view returns (address) {
        return revealed[i];
    }
}