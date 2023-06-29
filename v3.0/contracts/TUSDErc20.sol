// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TUSDErc20 is ERC20 {
    constructor() ERC20("Test USD", "TUSD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount); 
    }
}