// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import "hardhat/console.sol";

interface IXEN{
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function claimMintRewardAndShare(address other, uint256 pct) external;
    function claimMintRewardAndStake(uint256 pct, uint256 term) external;
    function stake(uint256 amount, uint256 term) external;
    function approve(address spender, uint256 amount) external returns (bool);
   // function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function transfer(address to,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
interface IMiniProxy{
    function withdraw(address token) external;
    function execute(address target, bytes memory data) external;
    function destroy(address payable recipient) external;
}

contract MiniProxy is IMiniProxy,Ownable{

    function withdraw(address token) public onlyOwner {
        uint256 balance = IXEN(token).balanceOf(address(this));
        IXEN(token).transfer(tx.origin, balance);
    }

    function execute(address target, bytes memory data) public onlyOwner
    {
        (bool success, ) = target.call(data);
        require(success, "Transaction failed.");
    }

    //销毁自己 并且将eth发送到recipient
    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }

}

contract xenAttackV3{

    address public xenContractAddress;
    mapping (address=>uint32) public countMintRank;
    
    constructor(address _xenAddress) {
        xenContractAddress = _xenAddress;
    }

    function batchMint(uint32 _numMint,uint32 _termDay) public {
        require(_numMint > 0,"numMint error!");
        require(_termDay >= 0,"termDat error!");
        uint32 MintIndex = countMintRank[msg.sender];
        for (uint i = MintIndex;i < MintIndex + _numMint;i++){
            //创建新合约
            bytes32 _salt = keccak256(abi.encodePacked(msg.sender, i));
            IMiniProxy newXenCallContract = new MiniProxy{salt: _salt}();
            if(_termDay == 0){
                uint64 termDay = 1;
                bytes memory data = abi.encodeWithSignature("claimRank(uint256)",termDay);
                IMiniProxy(address(newXenCallContract)).execute(xenContractAddress,data);
                termDay++;
            }else{
                bytes memory data = abi.encodeWithSignature("claimRank(uint256)",_termDay);
                IMiniProxy(address(newXenCallContract)).execute(xenContractAddress,data);
            }
        }
        countMintRank[msg.sender] = MintIndex + _numMint;
    }

    function batchClaimWithXenContract() public {
        uint32 mintNumber = countMintRank[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = getCreateAddress(msg.sender,i);
            bytes memory data = abi.encodeWithSignature("claimMintRewardAndShare(address,uint256)",msg.sender,100);
            IMiniProxy(_xenCallAddress).execute(xenContractAddress,data);
            IMiniProxy(_xenCallAddress).destroy(payable(msg.sender));
        }
    }

    function getCreateAddress(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(type(MiniProxy).creationCode)
            )))));
    }

    receive() external payable {}
}
