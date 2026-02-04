// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Lottery.sol";

/// @title Taxpayer Contract
/// @notice Models family relationships and tax allowance logic.
/// @dev Designed for security analysis using property-based fuzzing (Echidna).
///      Focuses on state consistency, allowance conservation, and safe interactions
///      with the Lottery contract.
contract Taxpayer {

  uint age; 

  bool isMarried; 

  bool iscontract;

  address spouse; 


  address  parent1; 
  address  parent2; 

  uint constant  DEFAULT_ALLOWANCE = 5000;

  uint constant ALLOWANCE_OAP = 7000;

  uint tax_allowance; 

  uint income; 

  uint256 rev;


  /// @notice Initializes a taxpayer with parent references.
  /// @param p1 Address of first parent.
  /// @param p2 Address of second parent.
  /// @dev Tax allowance is initialized to the baseline value.
  constructor(address p1, address p2) {
    age = 0;
    isMarried = false;
    parent1 = p1;
    parent2 = p2;
    spouse = address(0);
    income = 0;
    tax_allowance = DEFAULT_ALLOWANCE;
    iscontract = true;
  } 


  /// @notice Establishes a marriage with another Taxpayer contract.
  /// @param new_spouse Address of the spouse contract.
  /// @dev Enforces bidirectional marriage consistency.
  /// @custom:security Prevents self-marriage and asymmetric relationships (P1).
  function marry(address new_spouse) public {
    require(new_spouse != address(0), "invalid spouse");
    require(new_spouse != address(this), "self marriage");
    require(!isMarried && spouse == address(0), "already married");

    Taxpayer sp = Taxpayer(new_spouse);

    require(!sp.getIsMarriedForSSA(), "spouse already married");
    require(sp.getSpouseForSSA() == address(0), "spouse already married");

    spouse = new_spouse;
    isMarried = true;

    sp.marryBack(address(this));

  }

  /// @notice Completes the reciprocal side of a marriage.
  /// @param other Address of the initiating spouse.
  /// @dev Callable only by the spouse contract to ensure atomic updates.
  function marryBack(address other) public {
    require(msg.sender == other, "only spouse");
    require(other != address(0) && other != address(this), "invalid other");
    require(!isMarried && spouse == address(0), "already married");

    spouse = other;
    isMarried = true;
}

  function _baselineAllowance() internal view returns (uint) {
    return (age >= 65) ? ALLOWANCE_OAP : DEFAULT_ALLOWANCE;
  }

  function _refreshAllowanceFloor() internal {
      uint base = _baselineAllowance();
      if (tax_allowance < base) {
          tax_allowance = base;
      }
  }
 
  /// @notice Terminates the current marriage, if any.
  /// @dev Resets allowance to the baseline value and enforces reciprocal divorce.
  function divorce() public {
    if (spouse != address(0)) {
      address old = spouse;
      Taxpayer oldTp = Taxpayer(old);

      require(oldTp.getSpouseForSSA() == address(this), "not reciprocal");

      spouse = address(0);
      isMarried = false;

      tax_allowance = _baselineAllowance();

      oldTp.divorceBack(address(this));
    } else {
      spouse = address(0);
      isMarried = false;
      tax_allowance = _baselineAllowance();
    }
  } 

  /// @notice Completes the reciprocal side of a divorce.
  /// @param expectedSpouse Address of the divorcing spouse.
  /// @dev Callable only by the spouse contract to maintain consistency.
  function divorceBack(address expectedSpouse) public {
    require(msg.sender == expectedSpouse, "only spouse");
    require(spouse == expectedSpouse, "not reciprocal");

    spouse = address(0);
    isMarried = false;

    tax_allowance = _baselineAllowance();
  }

  /// @notice Convenience wrapper for reciprocal divorce.
  /// @dev Uses the caller address as expected spouse.
  function divorceBack() public {
    divorceBack(msg.sender);
  }


  /// @notice Transfers part of the tax allowance to the spouse.
  /// @param change Amount of allowance to transfer.
  /// @dev Allowed only between mutually married taxpayers.
  /// @custom:security Preserves allowance conservation (P2).
  function transferAllowance(uint change) public {
      require(isMarried, "not married");
      require(spouse != address(0), "no spouse");
      require(change > 0, "zero");
      require(change <= tax_allowance, "insufficient");

      if (age >= 65) {
          require(tax_allowance - change >= ALLOWANCE_OAP, "OAP min allowance");
      }

      Taxpayer sp = Taxpayer(spouse);

      require(sp.isContract(), "spouse not contract");
      require(sp.getSpouseForSSA() == address(this), "not reciprocal");

      tax_allowance -= change;

      sp.setTaxAllowance(sp.getTaxAllowance() + change);
  }

  /// @notice Increments the age of the taxpayer by one year.
  /// @dev Updates the minimum allowance if an age threshold is crossed.
  function haveBirthday() public {
    age++;
    _refreshAllowanceFloor();

  }

  /// @notice Sets the tax allowance value.
  /// @param ta New allowance value.
  /// @dev Callable only by trusted contracts (Taxpayer or Lottery).
  ///      Enforces a minimum baseline allowance.
  function setTaxAllowance(uint ta) public {
    require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());

    uint base = _baselineAllowance();
    if (ta < base) {
      tax_allowance = base;
    } else {
      tax_allowance = ta;
    }
  }

  /// @notice Returns the current tax allowance.
  function getTaxAllowance() public view returns(uint) {
    return tax_allowance;

  }

  /// @notice Indicates whether the caller is a contract instance.
  /// @dev Used for defensive checks in cross-contract interactions.
  function isContract() public view returns(bool){
    return iscontract;

  }

  /// @notice Commits participation in a Lottery.
  /// @param lot Address of the Lottery contract.
  /// @param r Secret value to commit.
  /// @dev Stores the secret locally for later reveal.
  function joinLottery(address lot, uint256 r) public {
    Lottery l = Lottery(lot);
    l.commit(keccak256(abi.encode(r)));
    rev = r;

  }

  /// @notice Reveals the committed value to the Lottery.
  /// @param lot Address of the Lottery contract.
  /// @param r Previously committed secret value.
  function revealLottery(address lot, uint256 r) public {
    Lottery l = Lottery(lot);
    l.reveal(r);
    rev = 0;

  }

  /// @notice Returns the spouse address, if married.
  function getSpouseForSSA() public view returns (address) {
    return spouse;
  }

  /// @notice Indicates whether the taxpayer is currently married.
  function getIsMarriedForSSA() public view returns (bool) {
    return isMarried;
  }

}
