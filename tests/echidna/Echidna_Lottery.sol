// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./LotteryHarness.sol";
import "./TaxpayerHarness.sol";

contract Echidna_Lottery {
    LotteryHarness internal L;

    TaxpayerHarness internal P0;
    TaxpayerHarness internal P1;
    TaxpayerHarness internal P2;

    mapping(address => uint256) internal lastR;

    constructor() {
        L = new LotteryHarness(1);
        P0 = new TaxpayerHarness(address(0), address(0));
        P1 = new TaxpayerHarness(address(0), address(0));
        P2 = new TaxpayerHarness(address(0), address(0));
    }

    function _pick(uint8 who) internal view returns (TaxpayerHarness) {
        uint8 w = who % 3;
        if (w == 0) return P0;
        if (w == 1) return P1;
        return P2;
    }

    function act_start(uint8) public {
        if (L.getStartTime() != 0) return;
        L.startLottery();
    }

    function act_commit(uint8 who, uint256 r) public {
        TaxpayerHarness p = _pick(who);
        if (L.getStartTime() == 0) return;
        lastR[address(p)] = r;
        p.joinLottery(address(L), r);
    }

    function act_reveal(uint8 who) public {
        TaxpayerHarness p = _pick(who);
        if (L.getStartTime() == 0) return;

        uint256 r = lastR[address(p)];
        if (L.getCommit(address(p)) == bytes32(0)) return;

        p.revealLottery(address(L), r);
    }

    function act_end(uint8) public {
        if (L.getEndTime() == 0) return;
        if (L.getRevealedLen() == 0) return;
        L.endLottery();
    }

    function echidna_L1_binding() public view returns (bool) {
        uint n = L.getRevealedLen();
        for (uint i = 0; i < n; i++) {
            address a = L.getRevealedAt(i);
            bytes32 c = L.getCommit(a);
            uint v = L.getReveal(a);
            if (keccak256(abi.encode(v)) != c) return false;
        }
        return true;
    }

    function echidna_L2_no_commit_when_not_started() public view returns (bool) {
        if (L.getStartTime() != 0) return true;
        if (L.getCommit(address(P0)) != bytes32(0)) return false;
        if (L.getCommit(address(P1)) != bytes32(0)) return false;
        if (L.getCommit(address(P2)) != bytes32(0)) return false;
        return true;
    }

    function echidna_L3_unique_reveals() public view returns (bool) {
        uint n = L.getRevealedLen();
        for (uint i = 0; i < n; i++) {
            address ai = L.getRevealedAt(i);
            for (uint j = i + 1; j < n; j++) {
                if (ai == L.getRevealedAt(j)) return false;
            }
        }
        return true;
    }
}