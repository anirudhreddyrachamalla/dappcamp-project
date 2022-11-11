// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multisigwallet;
    address[] _approvers;
    function setUp() public {
        uint _numOfConfirmationsRequired = 3;
        address _owner  = address(0xABCD);
        address testPrimaryAccount = address(0xABCD);
        address testSecondaryAccount = address(0xABDC);
        address testTertiaryAccount = address(0xABDCD);
        _approvers.push(testPrimaryAccount);
        _approvers.push(testSecondaryAccount);
        _approvers.push(testTertiaryAccount);
        
        multisigwallet = new MultiSigWallet(_numOfConfirmationsRequired,_approvers,_owner);
        
    }

    // function testIncrement() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
