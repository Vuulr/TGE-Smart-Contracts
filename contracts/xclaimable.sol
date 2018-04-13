pragma solidity ^0.4.19;

import "./zeppelin-solidity/contracts/ownership/Claimable.sol";

contract XClaimable is Claimable {

    function cancelOwnershipTransfer() onlyOwner public {
        pendingOwner = owner;
    }

}