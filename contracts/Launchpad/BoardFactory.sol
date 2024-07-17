// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Board.sol";
import "../Common/Ownable.sol";
import "./IOcean.sol";

contract BoardFactory is Ownable {
    address public tolToken;
    uint256 public minimumTOLRequired;

    IOcean public ocean;
    uint256 public launchpadCount;

    event LaunchpadCreated(
        uint256 indexed id,
        address launchpadAddress,
        uint256 minBuy,
        uint256 maxBuy,
        uint256 deadline,
        uint256 targetRaised,
        string cid
    );

    /**
     * @dev Initializes the contract with the provided TOL token address and minimum TOL required.
     * @param _tolToken The address of the TOL token contract.
     * @param _minimumTOLRequired The minimum amount of TOL tokens required to activate a launchpad.
     */
    constructor(address _tolToken, uint256 _minimumTOLRequired) {
        tolToken = _tolToken;
        minimumTOLRequired = _minimumTOLRequired;
    }

    /**
     * @dev Updates the Ocean contract instance.
     * @param _ocean The address of the new Ocean contract.
     */
    function updateOceanInstance(address _ocean) external onlyOwner {
        ocean = IOcean(_ocean);
    }

    /**
     * @dev Creates a new launchpad with the specified parameters.
     * @param _fundedToken The address of the funded token contract.
     * @param _minBuy The minimum amount of ETH required to participate in the presale.
     * @param _maxBuy The maximum amount of ETH allowed to participate in the presale.
     * @param _rates The conversion rate from ETH to funded tokens.
     * @param _deadline The deadline for the presale.
     * @param _targetRaised The target amount of ETH to be raised in the presale.
     * @param _rewardRatePerTOL The reward rate per TOL token placed.
     * @param _cid The content identifier for additional launchpad information.
     * @return The ID of the created launchpad stored in the Ocean contract.
     */
    function createLaunchpad(
        address _fundedToken,
        uint256 _minBuy,
        uint256 _maxBuy,
        uint256 _rates,
        uint256 _deadline,
        uint256 _targetRaised,
        uint256 _rewardRatePerTOL,
        string memory _cid
    ) external returns (uint256) {
        require(_minBuy > 0 && _maxBuy > _minBuy, "Invalid buy limits");
        require(_deadline > block.timestamp, "Invalid deadline");

        launchpadCount++;
        Board newLaunchpad = new Board(
            msg.sender,
            tolToken,
            _fundedToken,
            minimumTOLRequired,
            _minBuy,
            _maxBuy,
            _rates,
            _deadline,
            _targetRaised,
            _rewardRatePerTOL,
            _cid
        );

        uint256 id = ocean.storeProject(
            msg.sender,
            address(newLaunchpad),
            _cid
        );

        emit LaunchpadCreated(
            launchpadCount,
            address(newLaunchpad),
            _minBuy,
            _maxBuy,
            _deadline,
            _targetRaised,
            _cid
        );

        return id;
    }
}
