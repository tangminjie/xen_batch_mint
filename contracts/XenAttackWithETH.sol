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
    function transfer(address to,uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IxenCall{
    event WithdrawEmergency(address userAddress, uint256 amount);
    function callXenWithMint(uint64 termDay) external ;
    function callXenWithClaim() external;
    function callXenWithClaimAndShare(address other, uint256 pct) external;
    function callXenWithClaimAndStake(uint256 pct, uint256 term) external;
    function callXenWithStake(uint256 amount, uint256 term) external;
    //提取代币
    function reward(address to, uint256 amount) external; // send reward
    function withdrawEmergency(address to) external;

}

contract xenCall is IxenCall,Ownable{
    using SafeERC20 for IERC20;
    address public xenToken;
    IXEN private immutable xen;//IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);
    constructor (address xenAddress){
        xen = IXEN(xenAddress);
      
    }
    function callXenWithMint(uint64 termDay) public {
        require(address(xen) != address(0)," xenToken address is error!");
        //外部调用
        xen.claimRank(termDay);
    }

    function callXenWithClaim() public {
        require(address(xen) != address(0)," xenToken address is error!");
        xen.claimMintReward();
        console.log("xen.balanceOf(address(this): ",xen.balanceOf(address(this)));
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
    @notice Send reward to user
    @param to The address of awards 
    @param amount number of awards 
    */
    function reward(address to, uint256 amount) external onlyOwner{
        require(address(xen) != address(0)," xenToken address is error!");
        require(address(to) != address(0),"address is error!");
       // xen.approve(msg.sender,~uint256(0));
        xen.transfer(to,amount);
    } // send reward

    /**
    @notice withdraw token Emergency
    */
    function withdrawEmergency(address to) external onlyOwner{
        require(address(xen) != address(0),"xenToken address is error!");
        require(address(to) != address(0),"address is error!");
       // console.log("xen.balanceOf(address(this)2222: ",xen.balanceOf(address(this)));
        xen.transfer(to,xen.balanceOf(address(this)));
        emit WithdrawEmergency(to, xen.balanceOf(address(this)));
    }
}

contract xenAttack{

    address public xenContractAddress;
    mapping(address=>uint32) public userMintNumberMapping;
    mapping(address=>mapping(uint32=>address)) public userMintMapping;
    mapping(address=>bool) public claimedMapping;

    constructor(address _xenAddress) {
        xenContractAddress = _xenAddress;
    }

    function batchMint(uint64 _numMint,uint64 _termDay) public {
        require(_numMint > 0,"numMint error!");
        require(_termDay >= 0,"termDat error!");
        uint32 userMintNum = userMintNumberMapping[msg.sender];
        for (uint i =0;i<_numMint;i++){
            //创建新合约
            IxenCall newXenCallContract = new xenCall(xenContractAddress);
            userMintMapping[msg.sender][userMintNum] = address(newXenCallContract);
            claimedMapping[address(newXenCallContract)] = false;
            userMintNumberMapping[msg.sender] = ++ userMintNum;
            if(_termDay == 0){
                uint64 termDay = 1;
                IxenCall(address(newXenCallContract)).callXenWithMint(termDay);
                termDay++;
            }else{
                IxenCall(address(newXenCallContract)).callXenWithMint(_termDay);
            }
        }
    }

    function claimWithXenContract(address _xenCallAddress) public {
        //判断是否claim过
        require(claimedMapping[_xenCallAddress] == false,"the address is claimed!");
        IxenCall(_xenCallAddress).callXenWithClaim();
        claimedMapping[_xenCallAddress] = true;
    }

    function batchClaimWithXenContract() public {
        uint32 mintNumber = userMintNumberMapping[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = userMintMapping[msg.sender][i];
            require(claimedMapping[_xenCallAddress] == false,"the address is claimed!");
            IxenCall(_xenCallAddress).callXenWithClaim();
            claimedMapping[_xenCallAddress] = true;
        }
    }

    //募集提款
    function withdrawForXenCallContract() public {
        uint32 mintNumber = userMintNumberMapping[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = userMintMapping[msg.sender][i];
            IxenCall(_xenCallAddress).withdrawEmergency(msg.sender);
        }
    }
}
