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

interface IxenCall{
    event WithdrawEmergency(address userAddress, uint256 amount);
    function callXenWithMint(uint64 termDay) external ;
    function cllXenWithClaim() external;
    function callXenWithClaimAndShare(address other, uint256 pct) external;
    function callXenWithClaimAndStake(uint256 pct, uint256 term) external;
    function callXenWithStake(uint256 amount, uint256 term) external;
    //提取代币
    function withdrawEmergency(address to) external;
}

contract xenCallV2 is IxenCall,Ownable{
    using SafeERC20 for IERC20;
    address public xenToken;
    IXEN private immutable xen = IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);
    
    // constructor (address xenAddress){
    //     xen = IXEN(xenAddress);
    // }
    function callXenWithMint(uint64 termDay) public {
        require(address(xen) != address(0)," xenToken address is error!");
        //外部调用
        xen.claimRank(termDay);
    }

    function cllXenWithClaim() public {
        require(address(xen) != address(0)," xenToken address is error!");
        xen.claimMintReward();
    }
    
    //  other other adddress ,pct 1-100
    function callXenWithClaimAndShare(address other, uint256 pct) public {
        require(address(xen) != address(0)," xenToken address is error!");
        xen.claimMintRewardAndShare(other,pct);
    }

    function callXenWithClaimAndStake(uint256 pct, uint256 term)public{
         require(address(xen) != address(0)," xenToken address is error!");
         xen.claimMintRewardAndStake(pct,term);
    }

    function callXenWithStake(uint256 amount, uint256 term)public {
        xen.stake(amount,term);
    }

    /**
    @notice withdraw token Emergency
    */
    function withdrawEmergency(address to) external onlyOwner{
        require(address(xen) != address(0),"xenToken address is error!");
        require(address(to) != address(0),"address is error!");
        xen.transfer(to,xen.balanceOf(address(this)));
        emit WithdrawEmergency(to, xen.balanceOf(address(this)));
    }
}

contract xenAttackV2{

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
            IxenCall newXenCallContract = new xenCallV2{salt: _salt}();
            if(_termDay == 0){
                uint64 termDay = 1;
                IxenCall(address(newXenCallContract)).callXenWithMint(termDay);
                termDay++;
            }else{
                IxenCall(address(newXenCallContract)).callXenWithMint(_termDay);
            }
        }
        countMintRank[msg.sender] = MintIndex + _numMint;
    }

    function batchClaimWithXenContract() public {
        uint32 mintNumber = countMintRank[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = getCreateAddress(msg.sender,i);
            IxenCall(_xenCallAddress).callXenWithClaimAndShare(msg.sender,100);
        }
    }

    function testCreate2(address sender,uint i) public returns(address newAddress){
        bytes32 _salt = keccak256(abi.encodePacked(sender, i));
        newAddress = address(new xenCallV2{salt: _salt}());
        console.log("newAddress: ",newAddress);
    }

    function getCreateAddress(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(type(xenCallV2).creationCode)
            )))));
    }

}
