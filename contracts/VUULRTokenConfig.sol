pragma solidity ^0.4.18;

contract VUULRTokenConfig {
    string public constant NAME = "Vuulr Token";
    string public constant SYMBOL = "VUU";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}
