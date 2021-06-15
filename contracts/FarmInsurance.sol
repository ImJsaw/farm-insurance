// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./libs/SafeBEP20.sol";
import "./DummyOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Farm Insurance
/// @notice Simple farm insurance implement
/// @author _bing
contract FarmInsurance is Ownable{
    using SafeMath for uint;
	using SafeBEP20 for IBEP20;
	
	uint256 public currentPeriod;
	mapping (uint256 => uint256) public periodInsuranceProviderPool;
	mapping (uint256 => uint256) public periodInsuranceBuyerPool;
	mapping (address => mapping(uint256 => uint256)) public userInsuranceProvide;
	mapping (address => mapping(uint256 => uint256)) public userInsuranceBuy;
	
	mapping (uint256 => bool) public isInsuranceClaimable;
	mapping (address => mapping(uint256 => bool)) public isClaimed;
	
	DummyOracle oracle;
	uint256 rainFallThreshold;
	
    constructor (address _addr) {
		currentPeriod = 0;
		rainFallThreshold = 50;
		oracle = DummyOracle(_addr);
	}
	
	function provideInsurance() public payable{
		periodInsuranceProviderPool[currentPeriod] = periodInsuranceProviderPool[currentPeriod].add(msg.value* 10 **18);
		userInsuranceProvide[_msgSender()][currentPeriod] = userInsuranceProvide[_msgSender()][currentPeriod].add(msg.value* 10 **18);
	}
	
	function buyInsurance() public payable{
		periodInsuranceBuyerPool[currentPeriod] = periodInsuranceBuyerPool[currentPeriod].add(msg.value* 10 **18);
		userInsuranceBuy[_msgSender()][currentPeriod] = userInsuranceBuy[_msgSender()][currentPeriod].add(msg.value* 10 **18);
	}
	
	function claimInsurance(uint256 period) public {
		require(period < currentPeriod, "!claimable");
		require(!isClaimed[_msgSender()][period], "!claimable");
		isClaimed[_msgSender()][period] = true;
		
		uint pool = periodInsuranceBuyerPool[period].add(periodInsuranceProviderPool[period]);
		//provide insurance get reward if not insurance not claimable
		if(userInsuranceProvide[_msgSender()][period] > 0 && !isInsuranceClaimable[period]){
			uint256 reward = userInsuranceProvide[_msgSender()][period].mul(pool).div(periodInsuranceProviderPool[period]);
			payable(_msgSender()).transfer(reward.div(10 ** 18));
		}
		//buy insurance get reward if insurance claimable
		if(userInsuranceBuy[_msgSender()][period] > 0 && isInsuranceClaimable[period]){
			uint256 reward = userInsuranceBuy[_msgSender()][period].mul(pool).div(periodInsuranceBuyerPool[period]);
			payable(_msgSender()).transfer(reward.div(10 ** 18));
		}
	}
	
	//settle and close current period
    function settleInsurance() public onlyOwner{
		isInsuranceClaimable[currentPeriod] = getOracleData();
		currentPeriod++;
	}
	
	function getOracleData() private returns(bool){
		//if rain enough, insurance not claimable
		if(oracle.getRainFall(currentPeriod) > rainFallThreshold){
			return false;
		}
		//if lack rain, insurance claimable
		return true;
	}
	
	function setOracleAddress(address _addr)public onlyOwner{
		oracle = DummyOracle(_addr);
	}

	//in case some user transfer their token into contract
    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
    }
}