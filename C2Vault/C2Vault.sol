// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.5.0/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

//C2Vault allows a user to deploy a shared vault with a trusted contract.
//This intermediary contract allows users to cancel up until the trusted
//contract accepts and transfers out funds. 

contract C2Vault  {

    bool public initialized;

    bytes public bytecode;

    bytes32 public bytecodeHash;

    address public owner;

    //can be offchain app specific, or human identifier
    mapping (address => string) public _userIDs;

    //log user deposit address when vault created
    event userReg( address );

    //initialize and submit bytecode for sharedVault contract
    function initialize( bytes memory _bytecode ) public {
        require(initialized == false);
        initialized = true;
        owner = msg.sender;
        bytecode = _bytecode;
        bytecodeHash = keccak256(bytecode);
    }


    //msg.sender specific deposit address == shared vault contract address
    function depositAddress() public view returns(address){
        return Create2.computeAddress( bytes32(uint256(uint160(msg.sender))), bytecodeHash, address(this)  );
        
    }

    //bool for frontend display trigger
    function depositAddressDeployed() public view returns(bool) {
        return Address.isContract(depositAddress());
    }

    //builds vault and saves app specific ID or nickname
    function registerDepositAddress( string memory userID ) external {
        
        buildUserVault();
        _userIDs[msg.sender] = userID;
    }

    //deposit from user in ONE
    function deposit() external payable {
        require(msg.value > 0);
        address to = depositAddress();
        Address.sendValue( payable(to) , msg.value );
        //(bool success,) = payable(to).call{value: msg.value }("");
        //require(success);
    }

    //internal build user vault using Create2, msg.sender as salt and bytecode from sharedVault contract
    function buildUserVault() internal returns (address) {
        address userVault = Create2.deploy( 0 , bytes32(uint256(uint160(msg.sender))) , bytecode);
        emit userReg(msg.sender);
        return userVault;
        
    }

    //receive() external payable {}
    //fallback() external payable {}
    
}
