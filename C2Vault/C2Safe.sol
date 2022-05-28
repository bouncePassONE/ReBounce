// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.5.0/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

//C2Safe allows a user to deploy a Shared Safe for HRC20, HRC721 and HRC1155 assets.
contract C2Safe  {

    bool public initialized;
    
    //SafeSafe Contract bytecode
    bytes public bytecode;

    //Stored during initialize
    bytes32 public bytecodeHash;
    
    //Deployer address from msg.sender
    address public owner;

    //can be offchain app specific, or human identifier
    mapping (address => string) public userIDs;

    //log user deposit address when vault created
    event userReg( address );

    //initialize and submit bytecode for SafeSafe contract, store hash and owner
    function initialize( bytes memory _bytecode ) public {
        require(initialized == false);
        initialized = true;
        owner = msg.sender;
        bytecode = _bytecode;
        bytecodeHash = keccak256(bytecode);
    }


    //msg.sender specific deposit address == shared SafeSafe contract address
    function depositAddress() public view returns(address){
        return Create2.computeAddress( bytes32(uint256(uint160(msg.sender))), bytecodeHash, address(this)  );
        
    }

    //bool for frontend display trigger
    function depositAddressDeployed() public view returns(bool) {
        return Address.isContract(depositAddress());
    }

    //builds SafeSafe and stores app specific ID or nickname
    function registerDepositAddress( string memory userID ) external {
        
        buildSafeSafe();
        userIDs[msg.sender] = userID;
    }

    //deposit from user in ONE
    function deposit() external payable {
        require(msg.value > 0);
        address to = depositAddress();
        Address.sendValue( payable(to) , msg.value );
        //(bool success,) = payable(to).call{value: msg.value }("");
        //require(success);
    }

    //internal build user safe using Create2, msg.sender as salt and bytecode from SafeSafe contract
    function buildSafeSafe() internal returns (address) {
        address userSafe = Create2.deploy( 0 , bytes32(uint256(uint160(msg.sender))) , bytecode);
        emit userReg(msg.sender);
        return userSafe;
        
    }
    
    //withdraw ONE from C2Safe JustInCase(JIC)
    function withdraw(uint256 amount) external payable {
        require(msg.sender == owner);
        Address.sendValue( payable(msg.sender) , amount );
    }

    //receive() external payable {}
    //fallback() external payable {}
    
}
