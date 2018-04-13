pragma solidity ^0.4.19;

import "./xclaimable.sol";
import "./zeppelin-solidity/contracts/math/Math.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./VUULRToken.sol";
import "./Salvageable.sol";


contract VUULRVesting is XClaimable, Salvageable {
    using SafeMath for uint;

    struct VestingSchedule {
        uint lockPeriod;        // Amount of time in seconds between withdrawal periods. (EG. 6 months or 1 month)
        uint numPeriods;        // number of periods until done.
        uint tokens;       // Total amount of tokens to be vested.
        uint amountWithdrawn;   // The amount that has been withdrawn.
        uint startTime;
    }

    bool public started;
    

    VUULRToken public vestingToken;
    address public vestingWallet;
    uint public vestingOwing;
    uint public decimals;


    // Vesting schedule attached to a specific address.
    mapping (address => VestingSchedule) public vestingSchedules;

    event VestingScheduleRegistered(address registeredAddress, address theWallet, uint lockPeriod,  uint tokens);
    event Started(uint start);
    event Withdraw(address registeredAddress, uint amountWithdrawn);
    event VestingRevoked(address revokedAddress, uint amountWithdrawn, uint amountRefunded);
    event VestingAddressChanged(address oldAddress, address newAddress);

    function VUULRVesting(VUULRToken _vestingToken, address _vestingWallet ) public {
        require(_vestingToken != address(0));
        require(_vestingWallet != address(0));
        vestingToken = _vestingToken;
        vestingWallet = _vestingWallet;
        decimals = uint(vestingToken.decimals());
    }

    // Start vesting, Vesting starts now !!!
    // as long as TOKEN IS NOT PAUSED
    function start() public onlyOwner {
        require(!started);
        require(!vestingToken.paused());
        started = true;
        Started(now);

        // catch up on owing transfers
        if (vestingOwing > 0) {
            require(vestingToken.transferFrom(vestingWallet, address(this), vestingOwing));
            vestingOwing = 0;
        }
    }

    // Register a vesting schedule to transfer SENC from a group SENC wallet to an individual
    // wallet. For instance, from pre-sale wallet to individual presale contributor address.
    function registerVestingSchedule(address _newAddress, uint _numDays,
        uint _numPeriods, uint _tokens, uint startFrom) 
        public 
        canOperate 
    {

        uint _lockPeriod;
        
        // Let's not allow the common mistake....
        require(_newAddress != address(0));
        // Check that beneficiary is not already registered
        require(vestingSchedules[_newAddress].tokens == 0);

        // Some lock period sanity checks.
        require(_numDays > 0); 
        require(_numPeriods > 0);

        _lockPeriod = _numDays * 1 days;

        vestingSchedules[_newAddress] = VestingSchedule({
            lockPeriod : _lockPeriod,
            numPeriods : _numPeriods,
            tokens : _tokens,
            amountWithdrawn : 0,
            startTime : startFrom
        });
        if (started) {
            require(vestingToken.transferFrom(vestingWallet, address(this), _tokens));
        } else {
            vestingOwing = vestingOwing.add(_tokens);
        }

        VestingScheduleRegistered(_newAddress, vestingWallet, _lockPeriod, _tokens);
    }

    // whichPeriod returns the vesting period we are in 
    // 0 - before start or not eligible
    // 1 - n : the timeperiod we are in
    function whichPeriod(address whom, uint time) public view returns (uint period) {
        VestingSchedule memory v = vestingSchedules[whom];
        if (started && (v.tokens > 0) && (time >= v.startTime)) {
            period = Math.min256(1 + (time - v.startTime) / v.lockPeriod,v.numPeriods);
        }
    }

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary) public view returns (uint _amountVested) {
        VestingSchedule memory _vestingSchedule = vestingSchedules[beneficiary];
        // If it's past the end time, the whole amount is available.
        if ((_vestingSchedule.tokens == 0) || (_vestingSchedule.numPeriods == 0) || (now < _vestingSchedule.startTime)){
            return 0;
        }
        uint _end = _vestingSchedule.lockPeriod.mul(_vestingSchedule.numPeriods);
        if (now >= _vestingSchedule.startTime.add(_end)) {
            return _vestingSchedule.tokens;
        }
        uint period = now.sub(_vestingSchedule.startTime).div(_vestingSchedule.lockPeriod)+1;
        if (period >= _vestingSchedule.numPeriods) {
            return _vestingSchedule.tokens;
        }
        uint _lockAmount = _vestingSchedule.tokens.div(_vestingSchedule.numPeriods);

        uint vestedAmount = period.mul(_lockAmount);
        return vestedAmount;
    }


    function withdrawable(address beneficiary) public view returns (uint amount) {
        return vested(beneficiary).sub(vestingSchedules[beneficiary].amountWithdrawn);
    }

    function withdrawVestedTokens() public {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        if (vestingSchedule.tokens == 0)
            return;

        uint _vested = vested(msg.sender);
        uint _withdrawable = withdrawable(msg.sender);
        vestingSchedule.amountWithdrawn = _vested;

        if (_withdrawable > 0) {
            require(vestingToken.transfer(msg.sender, _withdrawable));
            Withdraw(msg.sender, _withdrawable);
        }
    }

    function revokeSchedule(address _addressToRevoke, address _addressToRefund) public onlyOwner {
        require(_addressToRefund != 0x0);

        uint _withdrawable = withdrawable(_addressToRevoke);
        uint _refundable = vestingSchedules[_addressToRevoke].tokens.sub(vested(_addressToRevoke));

        delete vestingSchedules[_addressToRevoke];
        if (_withdrawable > 0)
            require(vestingToken.transfer(_addressToRevoke, _withdrawable));
        if (_refundable > 0)
            require(vestingToken.transfer(_addressToRefund, _refundable));
        VestingRevoked(_addressToRevoke, _withdrawable, _refundable);
    }

    function changeVestingAddress(address _oldAddress, address _newAddress) public onlyOwner {
        VestingSchedule memory vestingSchedule = vestingSchedules[_oldAddress];
        require(vestingSchedule.tokens > 0);
        require(_newAddress != 0x0);
        require(vestingSchedules[_newAddress].tokens == 0x0);

        VestingSchedule memory newVestingSchedule = vestingSchedule;
        delete vestingSchedules[_oldAddress];
        vestingSchedules[_newAddress] = newVestingSchedule;

        VestingAddressChanged(_oldAddress, _newAddress);
    }

    function emergencyERC20Drain( ERC20 oddToken, uint amount ) public canOperate {
        // Cannot withdraw VUULRToken if vesting started
        require(!started || address(oddToken) != address(vestingToken));
        super.emergencyERC20Drain(oddToken,amount);
    }
}