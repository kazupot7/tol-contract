// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {
    constructor(
        address receiver,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(receiver, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract TokenFactory {
    event TokenCreated(address tokenAddress);

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public {
        ERC20Token newToken = new ERC20Token(
            msg.sender,
            name,
            symbol,
            initialSupply
        );
        newToken.transferOwnership(msg.sender);
        emit TokenCreated(address(newToken));
    }
}
