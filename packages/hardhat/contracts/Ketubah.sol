// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

error AlreadyInitialized();
error WitnessCannotBePartner();
error OnlyPartnerCanConsent();
error ConsentAlreadyRecorded();
error AlreadyMarried();
error AlreadyWitnessed();
error NotReadyForWitness();
error ContractAlreadyInvalidated();
error ContractAlreadyMigrated();
error TransfersDisabled();

contract SmartKetubah is Ownable, ERC1155 {
    // Track state of contract to enable features when conditions are met
    enum State {
        Engaged,
        Ready,
        Married,
        Invalidated,
        Migrated
    }

    State public contractState;

    event Initiated(address _partner1, address _partner2, string _uri);
    event UpdatedURI(string _uri);
    event Married(address _partner1, address _partner2, address _firstWitness);
    event Witnessed(address _witness, string _message);
    event Invalidated();
    event Migrated(address _newContract);

    mapping(address => bool) public consent; /*Track consent for addresses*/
    mapping(address => bool) public witnesses; /*Track witnesses*/

    string public marriageUri; /*Track terms of the marriage*/

    string public name; /*Token name override*/
    string public symbol; /*Token symbol override*/

    uint256 public witnessCount; /*Track how many witnesses have registered*/

    address public partner1;
    address public partner2;

    address public newContract; /*Track address of new contract if migration has ocurred*/

    /// @dev Contract uninitialized on deploy. Deployer is set as initial owner and can initialize
    constructor(
        string memory _tokenUri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_tokenUri) {
        name = _name;
        symbol = _symbol;
    }

    /// @notice Initialize the partner addresses and URI
    /// @dev Callable by owner
    /// @param _partner1 First marriage partner
    /// @param _partner2 Second marriage partner
    /// @param _marriageUri Terms of marriage
    function initialize(
        address _partner1,
        address _partner2,
        string memory _marriageUri
    ) external onlyOwner {
        if ((partner1 != address(0)) && (partner2 != address(0)))
            revert AlreadyInitialized(); /*Revert if both partners are already set*/
        partner1 = _partner1;
        partner2 = _partner2;
        marriageUri = _marriageUri;

        emit Initiated(_partner1, _partner2, _marriageUri);
    }

    /// @notice Update the terms
    /// @dev Callable by owner. Owner may be implemented as a Gnosis Safe with 2 partners
    function updateMarriageUri(string memory _marriageUri) external onlyOwner {
        marriageUri = _marriageUri;

        emit UpdatedURI(_marriageUri);
    }

    /// @notice Update the token URI
    /// @dev Callable by owner. Owner may be implemented as a Gnosis Safe with 2 partners
    function updateTokenUri(string memory _tokenUri) external onlyOwner {
        _setURI(_tokenUri);
    }

    /// @notice Consent to the marriage. Must be done before witnessing
    /// @dev Callable by each partner
    function recordConsent() external {
        if ((partner1 != msg.sender) && (partner2 != msg.sender))
            revert OnlyPartnerCanConsent(); /*Revert if called by someone other than a partner*/
        if (contractState != State.Engaged) revert AlreadyMarried(); /*Only allow consent if before married state*/
        if (consent[msg.sender] != false) revert ConsentAlreadyRecorded(); /*Only allow one consent per partner*/

        consent[msg.sender] = true;

        if (consent[partner1] && consent[partner2]) {
            contractState = State.Ready; /*Once both partners consent, change state to ready*/
        }
    }

    /// @notice Witness the marriage by a 3rd party. If first witness, moves state to married
    /// @dev Cannot be called by partners
    /// @param _message Message to emit in witness event
    function witness(string memory _message) external {
        if ((contractState != State.Married) && (contractState != State.Ready))
            revert NotReadyForWitness(); /*Revert if not in ready or married state*/
        if ((partner1 == msg.sender) || (partner2 == msg.sender))
            revert WitnessCannotBePartner(); /*Revert if partner tries to witness*/

        if (witnesses[msg.sender]) revert AlreadyWitnessed(); /*Revert if sender already witnessed*/

        if (witnessCount == 0) {
            contractState = State.Married; /*If first witness, change state to married*/
            _mint(partner1, 1, 1, "");
            _mint(partner2, 1, 1, "");
            emit Married(partner1, partner2, msg.sender);
        }

        witnessCount++;
        witnesses[msg.sender] = true;
        _mint(msg.sender, 2, 1, "");

        emit Witnessed(msg.sender, _message);
    }

    /// @notice Invalidate the marriage by owner. Owner may be implemented as a Gnosis safe with partners as signers
    function invalidate() external onlyOwner {
        if (contractState == State.Invalidated)
            revert ContractAlreadyInvalidated(); /*Revert if already invalidated*/
        if (contractState == State.Migrated) revert ContractAlreadyMigrated(); /*Revert if already migrated*/

        contractState = State.Invalidated;
        emit Invalidated();
    }

    /// @notice Migrate to new contract by owner. Owner may be implemented as a Gnosis safe with partners as signers
    function migrate(address _newContract) external onlyOwner {
        if (contractState == State.Invalidated)
            revert ContractAlreadyInvalidated(); /*Revert if already invalidated*/
        if (contractState == State.Migrated) revert ContractAlreadyMigrated(); /*Revert if already migrated*/

        newContract = _newContract;
        contractState = State.Migrated;
        emit Migrated(_newContract);
    }

    /// @dev Disable token transfers
    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal pure override {
        if (from != address(0)) revert TransfersDisabled(); /*Only allow mints*/
    }
}
