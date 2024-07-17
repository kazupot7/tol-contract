// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Common/Ownable.sol";
import "../ERC20/IERC20.sol";

contract Board is Ownable {
    enum Status {
        Pending,
        Active,
        Cancelled,
        Failed,
        Finalized
    }

    struct Launchpad {
        Status status;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 rates;
        uint256 deadline;
        string cid;
        uint256 totalRaised;
        uint256 targetRaised;
        uint256 totalTOLPlaced;
        mapping(address => uint256) contributions;
        mapping(address => uint256) tolContributions;
    }

    IERC20 public tolToken;
    IERC20 public fundedToken;
    uint256 public minimumTOLRequired;
    uint256 public minimumHoldTime;
    uint256 public rewardRatePerTOL;
    address[] public voters;

    Launchpad public launchpad;

    event PresaleBought(address buyer, uint256 amount);
    event TokenWithdrawal(address buyer, uint256 amount);
    event EmergencyWithdraw(address buyer, uint256 amount);
    event Refund(address buyer, uint256 amount);
    event PresaleCancelled();
    event PresaleFinalized(uint256 totalRaised);
    event TOLPlaced(address placer, uint256 amount);

    /**
     * @dev Initializes the contract with the provided parameters and sets the initial state of the launchpad.
     * @param _owner The address of the contract owner.
     * @param _tolToken The address of the TOL token contract.
     * @param _fundedToken The address of the funded token contract.
     * @param _minimumTOLRequired The minimum amount of TOL tokens required to activate the launchpad.
     * @param _minBuy The minimum amount of ETH required to participate in the presale.
     * @param _maxBuy The maximum amount of ETH allowed to participate in the presale.
     * @param _rates The conversion rate from ETH to funded tokens.
     * @param _deadline The deadline for the presale.
     * @param _targetRaised The target amount of ETH to be raised in the presale.
     * @param _rewardRatePerTOL The reward rate per TOL token placed.
     * @param _cid The content identifier for additional launchpad information.
     */
    constructor(
        address _owner,
        address _tolToken,
        address _fundedToken,
        uint256 _minimumTOLRequired,
        uint256 _minBuy,
        uint256 _maxBuy,
        uint256 _rates,
        uint256 _deadline,
        uint256 _targetRaised,
        uint256 _rewardRatePerTOL,
        string memory _cid
    ) {
        transferOwnership(_owner);
        tolToken = IERC20(_tolToken);
        fundedToken = IERC20(_fundedToken);
        minimumTOLRequired = _minimumTOLRequired;
        minimumHoldTime = tolToken.minimumHoldingTime();

        launchpad.status = Status.Pending;
        launchpad.minBuy = _minBuy;
        launchpad.maxBuy = _maxBuy;
        launchpad.rates = _rates;
        launchpad.deadline = _deadline;
        launchpad.targetRaised = _targetRaised;
        launchpad.cid = _cid;
        rewardRatePerTOL = _rewardRatePerTOL;
    }

    /**
     * @dev Returns the contribution amount for a specified address.
     * @param target The address to query the contribution for.
     * @return The contribution amount in ETH.
     */
    function getContribution(address target) external view returns (uint256) {
        return launchpad.contributions[target];
    }

    /**
     * @dev Returns the total number of voters who have placed TOL tokens.
     * @return The number of voters.
     */
    function totalVoters() external view returns (uint256) {
        return voters.length;
    }

    /**
     * @dev Calculates and returns the token amount for a specified address based on their contribution.
     * @param target The address to query the token amount for.
     * @return The token amount.
     */
    function getTokenAmount(address target) public view returns (uint256) {
        uint256 tokenAmount = (launchpad.contributions[target] *
            launchpad.rates *
            (10 ** 18)) / (10 ** 18);
        return tokenAmount;
    }

    /**
     * @dev Returns the details of the current launchpad.
     * @return The launchpad status, minBuy, maxBuy, rates, deadline, cid, totalRaised, targetRaised, and totalTOLPlaced.
     */
    function getLaunchpadDetail()
        external
        view
        returns (
            Status,
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            launchpad.status,
            launchpad.minBuy,
            launchpad.maxBuy,
            launchpad.rates,
            launchpad.deadline,
            launchpad.cid,
            launchpad.totalRaised,
            launchpad.targetRaised,
            launchpad.totalTOLPlaced
        );
    }

    /**
     * @dev Allows users to participate in the presale by sending ETH.
     * Emits a {PresaleBought} event.
     */
    function buyPresale() external payable {
        require(launchpad.status == Status.Active, "Presale is not active");
        require(block.timestamp < launchpad.deadline, "Presale has ended");
        require(
            msg.value >= launchpad.minBuy && msg.value <= launchpad.maxBuy,
            "Invalid amount"
        );
        require(
            launchpad.contributions[msg.sender] + msg.value <= launchpad.maxBuy,
            "Exceeds max buy limit"
        );

        launchpad.contributions[msg.sender] += msg.value;
        launchpad.totalRaised += msg.value;

        emit PresaleBought(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their tokens after the presale has been finalized.
     * Emits a {TokenWithdrawal} event.
     */
    function withdrawToken() external {
        require(
            launchpad.status == Status.Finalized,
            "Presale is not finalized"
        );

        uint256 tokenAmount = getTokenAmount(msg.sender);
        fundedToken.transfer(msg.sender, tokenAmount);

        emit TokenWithdrawal(msg.sender, tokenAmount);
    }

    /**
     * @dev Allows users to get a refund of their contribution if the presale failed.
     * Emits a {Refund} event.
     */
    function refund() external {
        require(launchpad.status == Status.Failed, "Presale is not failed");
        uint256 amount = launchpad.contributions[msg.sender];
        require(amount > 0, "No contribution found");

        payable(msg.sender).transfer(amount);

        emit Refund(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw their contribution in case of an emergency during an active presale.
     * Emits an {EmergencyWithdraw} event.
     */
    function emergencyWithdraw() external {
        require(launchpad.status == Status.Active, "Presale is not active");
        uint256 amount = launchpad.contributions[msg.sender];
        require(amount > 0, "No contribution found");

        launchpad.contributions[msg.sender] = 0;
        launchpad.totalRaised -= amount;

        payable(msg.sender).transfer(amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Allows the owner to cancel the presale if it is either pending or active.
     * Emits a {PresaleCancelled} event.
     */
    function cancelPresale() external onlyOwner {
        require(
            launchpad.status == Status.Active ||
                launchpad.status == Status.Pending,
            "Cannot cancel"
        );
        launchpad.status = Status.Cancelled;

        emit PresaleCancelled();
    }

    /**
     * @dev Finalizes the presale if it is active and the deadline has passed.
     * If the total raised amount is less than the target, the presale fails.
     * Otherwise, the presale is finalized and rewards are distributed.
     * Emits a {PresaleFinalized} event.
     */
    function finalizePresale() external onlyOwner {
        require(launchpad.status == Status.Active, "Presale is not active");
        require(block.timestamp >= launchpad.deadline, "Presale has not ended");

        if (launchpad.totalRaised < launchpad.targetRaised) {
            launchpad.status = Status.Failed;
        } else {
            launchpad.status = Status.Finalized;
            payable(owner()).transfer(launchpad.totalRaised);

            uint256 totalVoter = voters.length;
            for (uint256 i = 0; i < totalVoter; i++) {
                fundedToken.transfer(
                    voters[i],
                    launchpad.tolContributions[voters[i]] * rewardRatePerTOL
                );
            }
        }

        emit PresaleFinalized(launchpad.totalRaised);
    }

    /**
     * @dev Allows users to place TOL tokens into the launchpad if it is pending.
     * The user's TOL token holding time must meet the minimum requirement.
     * Emits a {TOLPlaced} event.
     * @param _amount The amount of TOL tokens to place.
     */
    function placeTOL(uint256 _amount) external {
        require(launchpad.status == Status.Pending, "Launchpad is not pending");
        uint256 firstHold = tolToken.getHoldingTime(msg.sender);
        require(
            block.timestamp >= firstHold + minimumHoldTime,
            "TOL hold time not met"
        );

        tolToken.transferFrom(msg.sender, address(this), _amount);
        launchpad.tolContributions[msg.sender] += _amount;
        launchpad.totalTOLPlaced += _amount;
        voters.push(msg.sender);

        if (launchpad.totalTOLPlaced >= minimumTOLRequired) {
            launchpad.status = Status.Active;
        }

        emit TOLPlaced(msg.sender, _amount);
    }

    /**
     * @dev Fallback function to prevent direct ETH transfers to the contract.
     */
    receive() external payable {
        revert("Do not send ETH directly");
    }
}
