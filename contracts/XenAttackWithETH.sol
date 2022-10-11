// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IxenCall{
    event WithdrawEmergency(address userAddress, uint256 amount);
    function callXenWithMint(address _xen,uint64 termDay) external ;
    function cllXenWithClaim() external;
    function reward(address _xenTokenAddress,address to, uint256 amount) external; // send reward
    function withdrawEmergency(address _xenTokenAddress,address to) external;

}

contract xenCall is IxenCall,Ownable{
    using SafeERC20 for IERC20;
    address public xenToken;

    function callXenWithMint(address _xen,uint64 termDay) public {
        //外部调用
    }

    function cllXenWithClaim() public {
        
    }

    /**
    @notice Send reward to user
    @param to The address of awards 
    @param amount number of awards 
    */
    function reward(address _xenTokenAddress,address to, uint256 amount) external onlyOwner{
        require(address(_xenTokenAddress) != address(0)," xenToken address is error!");
        require(address(to) != address(0),"address is error!");
        IERC20(_xenTokenAddress).safeTransfer(to,amount);
    } // send reward

    /**
    @notice withdraw token Emergency
    */
    function withdrawEmergency(address _xenTokenAddress, address to) external onlyOwner{
        require(address(_xenTokenAddress) != address(0),"xenToken address is error!");
        require(address(to) != address(0),"address is error!");
        IERC20(_xenTokenAddress).safeTransfer(to,IERC20(_xenTokenAddress).balanceOf(address(this)));
        emit WithdrawEmergency(to, IERC20(_xenTokenAddress).balanceOf(address(this)));
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
        if(_termDay == 0){
            for (uint i =0;i<_numMint;i++){
                uint64 termDay = 1;
                //创建新合约
                IxenCall newXenCallContract = new xenCall();
                userMintMapping[msg.sender][userMintNum] = address(newXenCallContract);
                claimedMapping[address(newXenCallContract)] = false;
                userMintNumberMapping[msg.sender] = ++ userMintNum;
                IxenCall(address(newXenCallContract)).callXenWithMint(xenContractAddress,termDay);
                termDay++;
            }
        }else{
            for (uint i =0;i<_numMint;i++){
                //创建新合约
                IxenCall newXenCallContract = new xenCall();
                userMintMapping[msg.sender][userMintNum] = address(newXenCallContract);
                claimedMapping[address(newXenCallContract)] = false;
                userMintNumberMapping[msg.sender] = ++ userMintNum;
                IxenCall(address(newXenCallContract)).callXenWithMint(xenContractAddress,_termDay);
            }
        }
        //        
    }

    function claimWithXenContract(address _xenCallAddress) public {
        //判断是否claim过
        require(claimedMapping[_xenCallAddress] == false,"the address is claimed!");
        IxenCall(_xenCallAddress).cllXenWithClaim();
        claimedMapping[_xenCallAddress] = true;
    }

    function batchClaimWithXenContract() public {
        uint32 mintNumber = userMintNumberMapping[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = userMintMapping[msg.sender][i];
            require(claimedMapping[_xenCallAddress] == false,"the address is claimed!");
            IxenCall(_xenCallAddress).cllXenWithClaim();
            claimedMapping[_xenCallAddress] = true;
        }
    }

    //募集提款
    function withdrawForXenCallContract() public {
        uint32 mintNumber = userMintNumberMapping[msg.sender];
        for(uint32 i=0;i<mintNumber;i++){
            address _xenCallAddress = userMintMapping[msg.sender][i];
            IxenCall(_xenCallAddress).withdrawEmergency(xenContractAddress,msg.sender);
        }
    }
}
