// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./LotteryHarness.sol";
import "./TaxpayerHarness.sol";

/// @title Echidna_Lottery
/// @notice Echidna property-based fuzzing harness for the Lottery contract.
/// @dev This contract drives arbitrary interactions against LotteryHarness
///      and checks protocol-level safety invariants.
contract Echidna_Lottery {
    /// @notice Lottery instance under test
    LotteryHarness internal L;

    /// @notice Test participant harnesses simulating independent users
    TaxpayerHarness internal P0;
    TaxpayerHarness internal P1;
    TaxpayerHarness internal P2;

    /// @dev Stores last random value used by each participant for reveal phase
    mapping(address => uint256) internal lastR;

    /// @notice Deploys the Lottery harness and three Taxpayer harnesses
    /// @dev Period is fixed to a small value to accelerate phase transitions
    constructor() {
        L = new LotteryHarness(1);
        P0 = new TaxpayerHarness(address(0), address(0));
        P1 = new TaxpayerHarness(address(0), address(0));
        P2 = new TaxpayerHarness(address(0), address(0));
    }

    /// @dev Selects one of the predefined participants based on input
    /// @param who Arbitrary selector provided by Echidna
    /// @return Selected TaxpayerHarness instance
    function _pick(uint8 who) internal view returns (TaxpayerHarness) {
        uint8 w = who % 3;
        if (w == 0) return P0;
        if (w == 1) return P1;
        return P2;
    }

    /// @notice Attempts to start the lottery
    /// @dev Silently ignores reverts to allow arbitrary call ordering
    function act_start(uint8) public {
        if (L.getStartTime() != 0) return;
        try L.startLottery() {} catch {}
    }

    /// @notice Attempts a commit action for a participant
    /// @param who Participant selector
    /// @param r Random value to be committed
    function act_commit(uint8 who, uint256 r) public {
        TaxpayerHarness p = _pick(who);
        if (L.getStartTime() == 0) return;
        lastR[address(p)] = r;
        try p.joinLottery(address(L), r) {} catch {}
    }

    /// @notice Attempts a reveal action for a participant
    /// @param who Participant selector
    function act_reveal(uint8 who) public {
        TaxpayerHarness p = _pick(who);
        if (L.getStartTime() == 0) return;

        if (L.getCommit(address(p)) == bytes32(0)) return;

        uint256 r = lastR[address(p)];
        try p.revealLottery(address(L), r) {} catch {}
    }

    /// @notice Attempts to finalize the lottery
    /// @dev Only meaningful after reveal phase
    function act_end(uint8) public {
        if (L.getEndTime() == 0) return;
        if (L.getRevealedLen() == 0) return;
        try L.endLottery() {} catch {}
    }

    /// @notice L1 — Commit–reveal binding
    /// @dev Every revealed value must match its commitment
    function echidna_L1_binding() public view returns (bool) {
        uint256 n = L.getRevealedLen();
        for (uint256 i = 0; i < n; i++) {
            address a = L.getRevealedAt(i);
            bytes32 c = L.getCommit(a);
            uint256 v = L.getReveal(a);
            if (c == bytes32(0)) return false;
            if (keccak256(abi.encode(v)) != c) return false;
        }
        return true;
    }

    /// @notice L2 — No commits before start
    /// @dev Participants cannot commit before the lottery has started
    function echidna_L2_no_commit_when_not_started() public view returns (bool) {
        if (L.getStartTime() != 0) return true;
        if (L.getCommit(address(P0)) != bytes32(0)) return false;
        if (L.getCommit(address(P1)) != bytes32(0)) return false;
        if (L.getCommit(address(P2)) != bytes32(0)) return false;
        return true;
    }

    /// @notice L3 — Unique reveals
    /// @dev Each revealed participant appears only once
    function echidna_L3_unique_reveals() public view returns (bool) {
        uint256 n = L.getRevealedLen();
        for (uint256 i = 0; i < n; i++) {
            address ai = L.getRevealedAt(i);
            for (uint256 j = i + 1; j < n; j++) {
                if (ai == L.getRevealedAt(j)) return false;
            }
        }
        return true;
    }

    /// @notice L4 — Phase correctness
    /// @dev Phase variables align correctly with the current phase
    function echidna_L4_phase_correctness() public view returns (bool) {
        uint8 p = L.getPhase();

        if (p == 0) {
            if (L.getStartTime() != 0) return false;
            if (L.getRevealTime() != 0) return false;
            if (L.getEndTime() != 0) return false;
        }

        if (p == 1 || p == 2) {
            if (L.getStartTime() == 0) return false;
            if (L.getRevealTime() == 0) return false;
            if (L.getEndTime() == 0) return false;
        }

        return true;
    }

    /// @notice L5 — Pot balance zero
    /// @dev The contract balance should be zero at all times
    function echidna_L5_pot_balance_zero() public view returns (bool) {
        return address(L).balance == 0;
        
    }

    /// @notice L6 — Winner validity
    /// @dev If a winner is set, there must be at least one revealed participant
    function echidna_L6_winner_validity() public view returns (bool) {
        address w = L.lastWinner();
        uint256 n = L.lastRevealedLen();

        if (w == address(0)) {
            return n == 0;
        }

        return n > 0;
    }
}