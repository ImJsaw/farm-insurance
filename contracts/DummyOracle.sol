// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DummyOracle
/// @notice simple oracle for demo
/// @author _bing
contract DummyOracle is Ownable{
    
	mapping (uint256 => uint256) monthRainFall;

	function getRainFall(uint256 period)public view returns(uint256){
		return monthRainFall[period];
	}
	
	function setRainFallData(uint256 period, uint256 data)public onlyOwner{
		monthRainFall[period] = data;
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