// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOcean {
    /**
     * @dev Verifies and updates the certification status of a project
     * @param _input Encoded input containing project ID and certification status
     * @return bool Returns true if the verification was successful
     */
    function verify(bytes calldata _input) external returns (bool);

    /**
     * @dev Boosts a project by spending TOL tokens
     * @param _projectId The ID of the project to boost
     * @param _tolAmount The amount of TOL tokens to spend on boosting
     */
    function boostProject(uint256 _projectId, uint256 _tolAmount) external;

    /**
     * @dev Terminates a project
     * @param _projectId The ID of the project to terminate
     */
    function terminateProject(uint256 _projectId) external;

    /**
     * @dev Stores a new project in the contract
     * @param _owner Address of the project owner
     * @param _contractAddress Address of the project's contract
     * @param _cid IPFS CID of the project's information
     */
    function storeProject(
        address _owner,
        address _contractAddress,
        string memory _cid
    ) external returns (uint256);
}
