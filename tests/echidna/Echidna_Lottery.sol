// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./LotteryHarness.sol";
import "./TaxpayerHarness.sol";
import "../../contracts/Taxpayer.sol";

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
    /// @dev Only callable when all committed participants have revealed (all-or-nothing)
    function act_end(uint8) public {
        if (L.getEndTime() == 0) return;
        if (L.getRevealedLen() == 0) return;
        if (L.getRevealedLen() != L.getCommittedLen()) return;
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

    /// @notice L2 — No reveal without a prior commit
    /// @dev The number of reveals can never exceed the number of commits
    function echidna_L2_no_reveal_without_commit() public view returns (bool) {
        return L.getRevealedLen() <= L.getCommittedLen();
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

    /// @notice L5 — State cleanup after finalization
    /// @dev After endLottery, all per-round state must be reset
    function echidna_L5_state_cleanup() public view returns (bool) {
        uint8 p = L.getPhase();
        if (p == 0 && L.lastWinner() != address(0)) {
            if (L.getCommittedLen() != 0) return false;
            if (L.getRevealedLen() != 0) return false;
            if (L.getStartTime() != 0) return false;
            if (L.getRevealTime() != 0) return false;
            if (L.getEndTime() != 0) return false;
        }
        return true;
    }

    /// @notice L7 — Participants must be under 65
    /// @dev Only taxpayers aged under 65 may commit to the lottery
    function echidna_L7_participants_under_65() public view returns (bool) {
        uint256 n = L.getCommittedLen();
        for (uint256 i = 0; i < n; i++) {
            address a = L.getCommittedAt(i);
            if (Taxpayer(a).getAge() >= 65) return false;
        }
        return true;
    }

    /// @notice L6 — Winner validity and all-or-nothing reveal
    /// @dev Winner exists only if all committed participants revealed (prevents selective-abort bias)
    function echidna_L6_winner_validity() public view returns (bool) {
        address w = L.lastWinner();
        uint256 rn = L.lastRevealedLen();
        uint256 cn = L.lastCommittedLen();

        if (w == address(0)) return rn == 0 && cn == 0;

        return rn > 0 && rn == cn;
    }
}