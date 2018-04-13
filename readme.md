VUULR (VUU) Token & Vesting Contracts
===

Built with open zeppelin commit 8d4eee4


Vesting
-------

Requires vesting wallet with enough tokens to fulfill all obligations.

Vesting wallet approves that amount for vesting contract to spend.

Constructor
---

* token (address of VUULR token)
* vestingWallet (A wallet that must have enough tokens to satisfy all the required vesting)

registerVestingSchedule
---

* newAddress (person to receive tokens)
* totalAmount (how many tokens they get)
* startFrom (they receive the first allocation on this date)
* numDays (how many **DAYS** between allocations)
* numPeriods (the total number of tokens is split into this many allocations)

If this is called after START (see below), the tokens will be transferred to the vesting contract.

If called before START, tokens are earmarked to be transferred when start is called.

start
---

Called once token transfers are enabled on the token contract.

withdrawVestedTokens
---

Allows Vestee to withdraw all tokens owing (meaning, the tokens that have already vested that have not yet been withdrawn before).

revokeSchedule
---

Assuming that a team member leaves, revoking them will cause all owing tokens to be sent to vestee, remaining tokens are sent to address supplied (i.e. returned to the company).

* addressToRevoke
* addressToRefund

changeVestingAddress
---

If a vestee has lost control of their address, we can reassign the allocation to a different address.

* oldAddress
* newAddress

whichPeriod
---

Only intended for diagnostics - allows us to check which period a vestee is in.

Returns zero if either
* no tokens assigned to this address
* vesting has not started

vested
---

Returns the beneficiary's total allowable tokens to date (including those already withdrawn).

withdrawable
---

Returns the amount that the beneficiary can withdraw now taking into account those already withdrawn.

emergencyERC20Drain
---

Allows us to extract ether and tokens that may have been inadvertently  sent or airdropped to this address (of the vesting contract).

**NOTE:** Will not allow VUULR tokens to be withdrawn after start because the contract is expected to hold VUULR tokens.
