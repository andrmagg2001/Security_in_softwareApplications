pragma solidity ^0.8.22;

import "./Lottery.sol";

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

  function divorceBack(address expectedSpouse) public {
    require(msg.sender == expectedSpouse, "only spouse");
    require(spouse == expectedSpouse, "not reciprocal");

    spouse = address(0);
    isMarried = false;

    tax_allowance = _baselineAllowance();
  }

  function divorceBack() public {
    divorceBack(msg.sender);
  }


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

  function haveBirthday() public {
    age++;
    _refreshAllowanceFloor();

  }

  function setTaxAllowance(uint ta) public {
    require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());

    uint base = _baselineAllowance();
    if (ta < base) {
      tax_allowance = base;
    } else {
      tax_allowance = ta;
    }
  }

  function getTaxAllowance() public view returns(uint) {
    return tax_allowance;

  }

  function isContract() public view returns(bool){
    return iscontract;

  }

  function joinLottery(address lot, uint256 r) public {
    Lottery l = Lottery(lot);
    l.commit(keccak256(abi.encode(r)));
    rev = r;

  }

  function revealLottery(address lot, uint256 r) public {
    Lottery l = Lottery(lot);
    l.reveal(r);
    rev = 0;

  }

  function getSpouseForSSA() public view returns (address) {
    return spouse;
  }

  function getIsMarriedForSSA() public view returns (bool) {
    return isMarried;
  }

}
