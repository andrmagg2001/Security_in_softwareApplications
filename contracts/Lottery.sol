// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";

/// @title Commit–Reveal Lottery
/// @author Andrea Maggiore
/// @notice Implements a time-based commit–reveal lottery protocol.
/// @dev The contract focuses on protocol correctness and state safety,
///      not on cryptographic randomness quality.
contract Lottery {

    /// @notice Execution phases of the lottery protocol.
    enum Phase {
        NotStarted,
        Commit,
        Reveal
    }

    /// @dev Commitment hashes submitted during the Commit phase.
    mapping(address => bytes32) internal commits;

    /// @dev Revealed values submitted during the Reveal phase.
    mapping(address => uint256) internal reveals;

    /// @dev Tracks whether an address has already committed in the current round.
    mapping(address => bool) internal hasCommitted;

    /// @dev Tracks whether an address has already revealed in the current round.
    mapping(address => bool) internal hasRevealed;

    /// @dev List of all addresses that committed in the current round.
    address[] internal committed;

    /// @dev List of all addresses that successfully revealed.
    address[] internal revealed;

    /// @dev Timestamp marking the start of the Commit phase.
    uint256 internal startTime;

    /// @dev Timestamp marking the start of the Reveal phase.
    uint256 internal revealTime;

    /// @dev Timestamp marking the end of the lottery round.
    uint256 internal endTime;

    /// @dev Duration of each phase (Commit and Reveal).
    uint256 internal period;

    /// @dev Constant flag used for testing and sanity checks.
    bool internal iscontract;

    /// @notice Winner of the last finalized lottery round.
    address public lastWinner;

    /// @notice Number of valid reveals in the last round.
    uint256 public lastRevealedLen;

    /// @dev Current protocol phase.
    Phase internal phase;

    /// @notice Deploys a new Lottery contract.
    /// @param p Duration of each phase in seconds.
    constructor(uint256 p) {
        period = p;
        iscontract = true;
        phase = Phase.NotStarted;
    }

    /// @notice Synchronizes the protocol phase with block timestamps.
    /// @dev Transitions Commit → Reveal when the reveal time is reached.
    /// @custom:security Enforces phase correctness (L4).
    function _syncPhase() internal {
        if (phase == Phase.Commit && block.timestamp >= revealTime) {
            phase = Phase.Reveal;
        }
    }

    /// @notice Starts a new lottery round.
    /// @dev Initializes timestamps and enters the Commit phase.
    function startLottery() public {
        require(phase == Phase.NotStarted, "already started");

        startTime = block.timestamp;
        revealTime = startTime + period;
        endTime = revealTime + period;
        phase = Phase.Commit;
    }

    /// @notice Submits a commitment for the current lottery round.
    /// @param y keccak256 hash of the secret value to be revealed later.
    /// @dev Callable only during the Commit phase and only once per address.
    /// @custom:security Enforces unique participation (L3).
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

    /// @notice Reveals the previously committed secret value.
    /// @param rev Original secret used to generate the commitment.
    /// @dev Callable only during the Reveal phase and only if a valid commit exists.
    /// @custom:security Enforces commit–reveal binding (L1) and no reveal without commit (L2).
    function reveal(uint256 rev) public {
        _syncPhase();

        require(phase == Phase.Reveal, "not reveal phase");
        require(block.timestamp >= revealTime, "too early");
        require(block.timestamp < endTime, "reveal closed");
        require(hasCommitted[msg.sender], "no commit");
        require(!hasRevealed[msg.sender], "double reveal");
        require(
            keccak256(abi.encode(rev)) == commits[msg.sender],
            "bad reveal"
        );

        hasRevealed[msg.sender] = true;
        reveals[msg.sender] = rev;
        revealed.push(msg.sender);
    }

    /// @notice Finalizes the lottery and selects a winner.
    /// @dev Computes the winner deterministically and resets all per-round state.
    /// @custom:security Enforces state cleanup (L5) and winner validity (L6).
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

        /// @dev External interaction performed after all checks.
        Taxpayer(winner).setTaxAllowance(7000);

        /// @dev Full cleanup of per-user state.
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

    /// @notice Returns whether this address corresponds to a contract instance.
    /// @dev Used for testing and sanity checks.
    function isContract() public view returns (bool) {
        return iscontract;
    }

    /// @notice Returns the start timestamp of the current round.
    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    /// @notice Returns the reveal phase start timestamp.
    function getRevealTime() external view returns (uint256) {
        return revealTime;
    }

    /// @notice Returns the end timestamp of the current round.
    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    /// @notice Returns the current protocol phase.
    function getPhase() external view returns (uint8) {
        return uint8(phase);
    }

    /// @notice Returns the commitment of an address.
    function getCommit(address a) external view returns (bytes32) {
        return commits[a];
    }

    /// @notice Returns the revealed value of an address.
    function getReveal(address a) external view returns (uint256) {
        return reveals[a];
    }

    /// @notice Returns whether an address has committed.
    function getHasCommitted(address a) external view returns (bool) {
        return hasCommitted[a];
    }

    /// @notice Returns whether an address has revealed.
    function getHasRevealed(address a) external view returns (bool) {
        return hasRevealed[a];
    }

    /// @notice Returns the number of committed participants.
    function getCommittedLen() external view returns (uint256) {
        return committed.length;
    }

    /// @notice Returns the committed address at index i.
    function getCommittedAt(uint256 i) external view returns (address) {
        return committed[i];
    }

    /// @notice Returns the number of revealed participants.
    function getRevealedLen() external view returns (uint256) {
        return revealed.length;
    }

    /// @notice Returns the revealed address at index i.
    function getRevealedAt(uint256 i) external view returns (address) {
        return revealed[i];
    }
}