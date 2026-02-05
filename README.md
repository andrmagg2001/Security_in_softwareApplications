# SSA Project — Security in Software Applications

This repository contains the coursework project for **Security in Software Applications (SSA)**.

Goal: define **security properties (things that must NOT happen)**, use **Echidna** to find counterexamples, identify the **root cause**, implement a **fix**, and re-run Echidna until all properties are **green**.

This README is written to be **reproducible 1:1** (same commands, same paths, same artifact locations).

---

## Repository layout

- `contracts/`
  - `Taxpayer.sol`
  - `Lottery.sol`
- `tests/echidna/`
  - `Echidna_Taxpayer_P1.sol`
  - `Echidna_Taxpayer_P2.sol`
  - `Echidna_Taxpayer_P3.sol`
  - `Echidna_All.sol` (Taxpayer consolidation)
  - `Echidna_Lottery.sol`
  - Harnesses (read-only getters): `TaxpayerHarness.sol`, `LotteryHarness.sol`
- `echidna/` (Echidna configs)
  - `taxpayer.yaml`, `taxpayer_p2.yaml`, `taxpayer_p3.yaml`, `all.yaml`, `lottery.yaml`
- `artifacts/`
  - `logs/` (raw outputs from runs)
  - `corpus/` (echidna corpus + reproducers + coverage)
- `artifacts/evidence/` (curated bundle for the report)
  - `all_release.txt`
  - `lottery/` (logs)
  - `screenshots/` (optional, when you capture FAIL/PASS images)

---

## What has been implemented

### Taxpayer (Parts 1–3)

**Part 1 — Marriage correctness**
- P1.1 Symmetry: if `spouse(a) == b` and `b != 0` then `spouse(b) == a`
- P1.2 No self-marriage: `spouse(a) != a`
- P1.3 Coherent “unmarried”: if `spouse(a) == 0` then no `x` exists with `spouse(x) == a`

**Part 2 — Allowance baseline + pooling conservation**
- Baseline: if `spouse(a) == 0` then `allowance(a) == 5000`
- Pooling conservation (reciprocal spouses): `allowance(a) + allowance(b) == 10000`

**Part 3 — Age ≥ 65 ⇒ allowance floor 9000**
- OAP minimum: if `age >= 65` then `allowance >= 9000`

A harness is used to expose internal state through **read-only getters** (no state changes), so Echidna can observe invariants.

### Lottery (Part 4 — Commit/Reveal)

The `Lottery` contract implements a simple **commit–reveal** protocol with phases:
`start → commit → reveal → end`.

Properties validated with Echidna:
- **L1 Binding**: a revealed value must match the prior commitment
- **L2 No commit when not started**: commits are only allowed during the Commit phase
- **L3 Unique reveals**: a participant cannot appear twice in the `revealed` list
- **L4 Phase correctness**: `commit`, `reveal`, `endLottery` only callable in the correct phase
- **L5 Pot/accounting conservation (model)**: the modeled pot is fully settled after finalization
- **L6 Winner validity**: no mod/div-by-zero and winner is picked from `revealed`
- **Prize semantics**: upon winning, the taxpayer allowance is increased to **9000**, in accordance with the updated project specification.

---

## How to reproduce (Docker)

### Prerequisites
- Docker installed and running.

All commands must be executed from the repository root.

### Lottery — smoke (80k)

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD":/src -w /src \
  trailofbits/echidna:latest \
  echidna-test tests/echidna/Echidna_Lottery.sol \
    --config echidna/lottery.yaml \
    --test-limit 80000 \
    --contract Echidna_Lottery \
  | tee artifacts/logs/lottery_PASS_smoke.txt
```

### Lottery — release (300k)

Make sure `echidna/lottery.yaml` contains:
- `testLimit: 300000`
- `seqLen: 80`
- `shrinkLimit: 8000`
- `corpusDir: artifacts/corpus/lottery`

Then run:

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD":/src -w /src \
  trailofbits/echidna:latest \
  echidna-test tests/echidna/Echidna_Lottery.sol \
    --config echidna/lottery.yaml \
    --contract Echidna_Lottery \
  | tee artifacts/logs/lottery_PASS_release.txt
```

### Taxpayer — consolidated suite (Echidna_All)

Smoke (example 80k):

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD":/src -w /src \
  trailofbits/echidna:latest \
  echidna-test tests/echidna/Echidna_All.sol \
    --config echidna/all.yaml \
    --test-limit 80000 \
    --contract Echidna_All \
  | tee artifacts/logs/all_PASS_smoke.txt
```

Release (example 300k — set it inside `echidna/all.yaml` or pass `--test-limit 300000`):

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD":/src -w /src \
  trailofbits/echidna:latest \
  echidna-test tests/echidna/Echidna_All.sol \
    --config echidna/all.yaml \
    --contract Echidna_All \
  | tee artifacts/logs/all_PASS_release.txt
```

Notes:
- The `--contract ...` flag is required because multiple contracts are present.
- The message `Ticker: poll failed: Interrupted system call` can appear; it does not affect correctness.

---

## Evidence locations

### Raw logs
- `artifacts/logs/` (all command outputs)

### Echidna corpus / coverage
- `artifacts/corpus/lottery/`
- `artifacts/corpus/<other_suites>/` (depending on `corpusDir` in each yaml)

### Curated evidence bundle (for report)
- `artifacts/evidence/all_release.txt`
- `artifacts/evidence/lottery/lottery_FAIL_initial.txt`
- `artifacts/evidence/lottery/lottery_PASS_smoke.txt`
- `artifacts/evidence/lottery/lottery_PASS_release.txt`
- `artifacts/evidence/screenshots/` (optional)

---

## Current status

- Taxpayer Parts 1–3: **implemented + passing (individual + consolidated suite)**
- Lottery Part 4 (L1–L6, including L5): **implemented + passing**

Remaining work is mainly **packaging + report** (≤10 pages): curated evidence, screenshots (FAIL/PASS), and write-up.
