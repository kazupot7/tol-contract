// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public claimInterval;

    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed claimer, uint256 amount);

    /**
     * @dev Constructor to initialize the faucet contract.
     * @param _token Address of the ERC20 token to be dispensed by the faucet.
     * @param _claimAmount Amount of tokens to be dispensed per claim.
     * @param _claimInterval Interval time in seconds between claims.
     */
    constructor(
        address _token,
        uint256 _claimAmount,
        uint256 _claimInterval
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        claimAmount = _claimAmount;
        claimInterval = _claimInterval;
    }

    /**
     * @dev Function to set the claim amount.
     * @param _claimAmount New claim amount.
     */
    function setClaimAmount(uint256 _claimAmount) external onlyOwner {
        claimAmount = _claimAmount;
    }

    /**
     * @dev Function to set the claim interval.
     * @param _claimInterval New claim interval in seconds.
     */
    function setClaimInterval(uint256 _claimInterval) external onlyOwner {
        claimInterval = _claimInterval;
    }

    /**
     * @dev Function to claim tokens from the faucet.
     */
    function claimTokens() external {
        require(
            block.timestamp - lastClaimed[msg.sender] >= claimInterval,
            "Claim interval has not passed"
        );

        lastClaimed[msg.sender] = block.timestamp;
        require(
            token.transfer(msg.sender, claimAmount),
            "Token transfer failed"
        );

        emit TokensClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Function to withdraw tokens from the faucet by the owner.
     * @param _amount Amount of tokens to withdraw.
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }

    /**
     * @dev Function to deposit tokens into the faucet.
     * @param _amount Amount of tokens to deposit.
     */
    function depositTokens(uint256 _amount) external onlyOwner {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
    }
}
