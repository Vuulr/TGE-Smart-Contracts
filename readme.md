VUULR (VUU) Token & Vesting Contracts
===

3rd Party Audit
-------

We engaged [Bluzelle](https://bluzelle.com/) to conduct an independent audit of our Token (VUULRToken.sol) and Vesting (VUULRVesting.sol) contracts that we will be using in support of the token sale (TGE, Token Generation Event), and general token economy as needed for the business.

We have included Bluzelle's audit findings in this repo, file named [Vuulr_Audit_Report_2018-04-17_Bluzelle.pdf](Vuulr_Audit_Report_2018-04-17_Bluzelle.pdf).

Should you have any questions regarding this audit, please reach out to the team by emailing tge.tech@vuulr.com.


Libraries
-------
We make use of the OpenZeppelin libraries, specifically commit [8d4eee4](https://github.com/OpenZeppelin/zeppelin-solidity/tree/8d4eee412d07ed938f9e8794ab183e67d86f764b).


Contract 1: VUU Token
-------

Fully ERC20 compliant token contract.

Code: [VUULRToken.sol](contracts/VUULRToken.sol)
Token Configuration: [VUULRTokenConfig.sol](contracts/VUULRTokenConfig.sol)

* **Name of Token:** Vuulr Token
* **Token Symbol:** VUU
* **Token Decimals:** 18
* **Total Supply:** 1,000,000,000


Contract 2: Vesting Contract
-------

This contract will be used to administer distribution of tokens to a recipient according to a vesting schedule. Users of this would be Vuulr employees or partners.

### General

Requires vesting wallet with enough tokens to fulfill all obligations.

Vesting wallet approves that amount for vesting contract to spend.

### Constructor

* token (address of VUULR token)
* vestingWallet (A wallet that must have enough tokens to satisfy all the required vesting)

### registerVestingSchedule

* newAddress (person to receive tokens)
* totalAmount (how many tokens they get)
* startFrom (they receive the first allocation on this date)
* numDays (how many **DAYS** between allocations)
* numPeriods (the total number of tokens is split into this many allocations)

If this is called after START (see below), the tokens will be transferred to the vesting contract.

If called before START, tokens are earmarked to be transferred when start is called.

### start

Called once token transfers are enabled on the token contract.

### withdrawVestedTokens

Allows Vestee to withdraw all tokens owing (meaning, the tokens that have already vested that have not yet been withdrawn before).

### revokeSchedule

Assuming that a team member leaves, revoking them will cause all owing tokens to be sent to vestee, remaining tokens are sent to address supplied (i.e. returned to the company).

* addressToRevoke
* addressToRefund

### changeVestingAddress

If a vestee has lost control of their address, we can reassign the allocation to a different address.

* oldAddress
* newAddress

### whichPeriod

Only intended for diagnostics - allows us to check which period a vestee is in.

Returns zero if either
* no tokens assigned to this address
* vesting has not started

### vested

Returns the beneficiary's total allowable tokens to date (including those already withdrawn).

### withdrawable

Returns the amount that the beneficiary can withdraw now taking into account those already withdrawn.

### emergencyERC20Drain

Allows us to extract ether and tokens that may have been inadvertently  sent or airdropped to this address (of the vesting contract).

**NOTE:** Will not allow VUULR tokens to be withdrawn after start because the contract is expected to hold VUULR tokens.
