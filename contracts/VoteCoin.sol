// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * 持有ERC20代币VTC才能参与投票,1 VTC = 1 Voting power.
 */
contract VoteCoin is ERC20, Ownable ,ERC20Burnable{

    constructor() ERC20("VoteCoin", "VTC") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}