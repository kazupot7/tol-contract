// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Common/Ownable.sol";
import "../ERC20/IERC20.sol";
import "../Math/SafeMath.sol";

contract Ocean is Ownable {
    using SafeMath for uint256;

    struct Project {
        address owner;
        address contractAddress;
        string cid;
        uint256 boostPoint;
        bool isTerminated;
        bool isCertified;
    }

    mapping(uint256 => Project) public projects;
    uint256 public projectCount;
    uint256 public boostRate;

    // Events for various project actions
    event ProjectStored(
        uint256 indexed projectId,
        address indexed owner,
        address contractAddress,
        string cid
    );
    event ProjectUpdated(uint256 indexed projectId, string cid);
    event ProjectTerminated(uint256 indexed projectId);
    event ProjectBoosted(
        uint256 indexed projectId,
        address booster,
        uint256 newBoostPoints
    );
    event CertificationUpdated(uint256 indexed projectId, bool isCertified);

    address public factoryAddress;
    address public tolAddress;
    address public treasuryAddress;

    modifier onlyProjectOwner(uint256 _projectId) {
        require(
            projects[_projectId].owner == msg.sender,
            "Only the project owner can call this function"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == factoryAddress,
            "Only the factory can call this function"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the contract
     * @param factory Address of the factory contract
     * @param token Address of the TOL token contract
     */
    constructor(address factory, address token, address _treasuryAddress) {
        factoryAddress = factory;
        tolAddress = token;
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @dev Update boost rate point
     * @param amount The amount of the boost rate to update
     */
    function setBoostRate(uint256 amount) external onlyOwner {
        boostRate = amount;
    }

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
    ) external onlyFactory returns (uint256) {
        projectCount++;
        projects[projectCount] = Project({
            owner: _owner,
            contractAddress: _contractAddress,
            cid: _cid,
            boostPoint: 0,
            isTerminated: false,
            isCertified: false
        });

        emit ProjectStored(projectCount, msg.sender, _contractAddress, _cid);

        return projectCount;
    }

    /**
     * @dev Updates the CID of an existing project
     * @param _projectId The ID of the project to update
     * @param newCid The new IPFS CID for the project's information
     */
    function updateProject(
        uint256 _projectId,
        string memory newCid
    ) external onlyProjectOwner(_projectId) {
        require(
            _projectId <= projectCount && _projectId > 0,
            "Invalid project ID"
        );
        require(!projects[_projectId].isTerminated, "Project is terminated");

        projects[_projectId].cid = newCid;
        emit ProjectUpdated(_projectId, newCid);
    }

    /**
     * @dev Terminates a project
     * @param _projectId The ID of the project to terminate
     */
    function terminateProject(uint256 _projectId) external onlyOwner {
        require(
            _projectId <= projectCount && _projectId > 0,
            "Invalid project ID"
        );
        require(
            !projects[_projectId].isTerminated,
            "Project is already terminated"
        );

        projects[_projectId].isTerminated = true;
        emit ProjectTerminated(_projectId);
    }

    /**
     * @dev Boosts a project by spending TOL tokens
     * @param _projectId The ID of the project to boost
     * @param _tolAmount The amount of TOL tokens to spend on boosting
     */
    function boostProject(uint256 _projectId, uint256 _tolAmount) external {
        require(
            _projectId <= projectCount && _projectId > 0,
            "Invalid project ID"
        );
        require(!projects[_projectId].isTerminated, "Project is terminated");
        require(_tolAmount > 0, "TOL amount cannot be zero");

        IERC20(tolAddress).transferFrom(
            msg.sender,
            treasuryAddress,
            _tolAmount
        );

        uint256 boosted = _tolAmount.div(10 ** 18) / boostRate;
        projects[_projectId].boostPoint += boosted;

        emit ProjectBoosted(
            _projectId,
            msg.sender,
            projects[_projectId].boostPoint
        );
    }

    /**
     * @dev Verifies and updates the certification status of a project
     * @param _input Encoded input containing project ID and certification status
     * @return bool Returns true if the verification was successful
     */
    function verify(bytes calldata _input) external returns (bool) {
        (uint256 projectId, bool isCertified) = abi.decode(
            _input,
            (uint256, bool)
        );

        require(
            projectId <= projectCount && projectId > 0,
            "Invalid project ID"
        );

        projects[projectId].isCertified = isCertified;
        emit CertificationUpdated(projectId, isCertified);

        return true;
    }

    /**
     * @dev Fallback function to reject direct payments
     */
    receive() external payable {
        revert("This contract does not accept direct payments");
    }
}
