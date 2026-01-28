pragma solidity ^0.8.22;

import "./Lottery.sol";

contract Taxpayer {

  uint age; 

  bool isMarried; 

  bool iscontract;

  /* Reference to spouse if person is married, address(0) otherwise */
  address spouse; 


  address  parent1; 
  address  parent2; 

  /* Constant default income tax allowance */
  uint constant  DEFAULT_ALLOWANCE = 5000;

  /* Constant income tax allowance for Older Taxpayers over 65 */
  uint constant ALLOWANCE_OAP = 7000;

  /* Income tax allowance */
  uint tax_allowance; 

  uint income; 

  uint256 rev;


  //Parents are taxpayers
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


  //We require new_spouse != address(0);
  function marry(address new_spouse) public {
    require(new_spouse != address(0), "invalid spouse");
    require(new_spouse != address(this), "self marriage");
    require(!isMarried && spouse == address(0), "already married");

    Taxpayer sp = Taxpayer(new_spouse);

    // partner must be free
    require(!sp.getIsMarriedForSSA(), "spouse already married");
    require(sp.getSpouseForSSA() == address(0), "spouse already married");

    // set my side
    spouse = new_spouse;
    isMarried = true;

    // set other side (one-way sync, no recursion)
    sp.marryBack(address(this));

  }

  function marryBack(address other) public {
    // only the "other" contract can finalize on this side
    require(msg.sender == other, "only spouse");
    require(other != address(0) && other != address(this), "invalid other");
    require(!isMarried && spouse == address(0), "already married");

    spouse = other;
    isMarried = true;
}
 
  function divorce() public {
    if (spouse != address(0)) {
        address old = spouse;

        spouse = address(0);
        isMarried = false;

        tax_allowance = DEFAULT_ALLOWANCE;

        Taxpayer(old).divorceBack();
    } else {
        spouse = address(0);
        isMarried = false;
        tax_allowance = DEFAULT_ALLOWANCE;
    }
}

function divorceBack() public {
    require(msg.sender == spouse, "only spouse");
    spouse = address(0);
    isMarried = false;

    tax_allowance = DEFAULT_ALLOWANCE;
}


  /* Transfer part of tax allowance to own spouse */
  function transferAllowance(uint change) public {
    require(spouse != address(0), "not married");
    require(isMarried, "not married");
    require(change > 0, "zero");
    require(change <= tax_allowance, "insufficient");

    Taxpayer sp = Taxpayer(spouse);

    require(sp.isContract(), "spouse not contract");
    require(sp.getSpouseForSSA() == address(this), "not reciprocal");

    tax_allowance = tax_allowance - change;
    sp.setTaxAllowance(sp.getTaxAllowance() + change);
}

  function haveBirthday() public {
    age++;
  }
 
  function setTaxAllowance(uint ta) public {
    require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
    tax_allowance = ta;
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
