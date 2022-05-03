// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.5.0/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

//ReBounce allows a user to deploy a shared vault with a trusted contract.
//This intermediary contract serves as an escrow account for pull payments between accounts.

contract ReBounce {
    
    // modifier one run
    bool public initialized;
    
    // Vault contract bytecode
    bytes public bytecode;

    // Create2 needed hash of bytecode "keccak256(bytecode)"
    bytes32 public bytecodeHash;
    
    // Probably not needed
    address public owner;
    
    // Register address with offchain userIDs - optional
    mapping (address => uint256) public _userIDs;
    

    function initialize( bytes memory _bytecode ) public {
        require(initialized == false);
        initialized = true;
        owner = msg.sender;
        bytecode = _bytecode;
        bytecodeHash = keccak256(bytecode);
    }
    
    // Computes address of escrow account based on msg.sender address
    function depositAddress() public view returns(address){
        return Create2.computeAddress( bytes32(uint256(uint160(msg.sender))), bytecodeHash, address(this)  );
        
    }
    
    // Register an offchain userID from CEX etc.
    // Build using create2 with vault contract bytecode
    // Callable only once by design
    function registerDepositAddress( uint256 userID ) external {  
        buildUserVault();
        _userIDs[msg.sender] = userID;
    }
    
    // Deposit directly to escrow address
    function deposit() external payable {
        require(msg.value > 0);
        address to = depositAddress();
        (bool success,) = payable(to).call{value: msg.value }("");
        require(success);
    }
    
    // ?approve only in escrow or transfer
    function depositHRC20( address _token , uint256 _amount ) external {
        IERC20( _token ).approve( depositAddress() , _amount );
    }
    
    // Internal Create2 deploy using msg.sender as salt
    function buildUserVault() internal returns (address) {
        address userVault = Create2.deploy( 0 , bytes32(uint256(uint160(msg.sender))) , bytecode);
        return userVault;
    }

}
