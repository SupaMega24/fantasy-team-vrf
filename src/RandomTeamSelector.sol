// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing Chainlink's VRFConsumerBaseV2Plus for verifiable randomness
// Importing Chainlink's VRFV2PlusClient library for VRF requests
// Importing the TeamNames contract which contains team names data
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {TeamNames} from "./TeamNames.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Random Team Selector/Fantasy
 * @author Charlie J
 * @dev This contract inherits VRFConsumerBaseV2Plus to get randomness from vrfCoordinator
 * and TeamNames to get names randomly from a list
 */

contract RandomTeamSelector is VRFConsumerBaseV2Plus, TeamNames {
    // *****Errors*****
    error RandomTeamSelector__AlreadySelected();
    error RandomTeamSelector__NoSelectionOptionsAvailable();
    error RandomTeamSelector__SelectionNotMade();
    error RandomTeamSelector__InvalidTeamChoice();

    // ***** State Variables *****
    uint256 private constant SELECTION_ONGOING = 24; // arbitrary number, no meaning
    uint256 private immutable i_subscriptionId; // Subscription ID for the Chainlink VRF service
    address private immutable i_vrfCoordinator; // Sepolia vrfCoordinator
    bytes32 private immutable i_keyHash; // Sepolia Gas LaneGas Lane
    uint32 private immutable i_callbackGasLimit; // Gas limit for the VRF callback function
    uint16 private immutable i_requestConfirmations; // Number of confirmations required for the VRF request
    uint32 private immutable i_numWords; // Number of random words to request

    // Struct to store manager's team selection options and their final choice
    struct ManagerSelection {
        uint256[] teamOptions;
        uint256 selectedTeam;
    }

    /**
     * @notice Mappings explained in order as listed
     * Mapping to associate VRF request IDs with managers' addresses
     * Mapping to store each manager's selection details
     */

    mapping(uint256 => address) private s_requestToManager;
    mapping(address => ManagerSelection) private s_managerSelections;

    /**
     * @notice Events explained in order as listed below
     * SelectionMade emitted when a selection is made
     * SelectionRevealed emitted when the random selection is revealed
     * TeamChosen emitted when a manager chooses a team
     */

    event SelectionMade(uint256 indexed requestId, address indexed manager);
    event SelectionRevealed(uint256 indexed requestId, uint256[] teamValues);
    event TeamChosen(address indexed manager, uint256 teamId);

    /**
     * @notice Constructor to set up the random team selector contract
     * It inherits the VRFConsumerBaseV2Plus
     * @param subscriptionId...etc variables needed for The Chainlink VRF
     */

    constructor(
        address vrfCoordinator,
        uint256 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_vrfCoordinator = vrfCoordinator;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        i_numWords = numWords;
    }

    /**
     * @notice Initiates the process to randomly select team names for a manager
     * @dev Only the owner can call this function. Emits the SelectionMade event.
     * @param manager The address of the manager requesting random teams
     * @return requestId The request ID of the VRF request
     */

    function requestRandomTeamNames(
        address manager
    ) public onlyOwner returns (uint256 requestId) {
        if (s_managerSelections[manager].teamOptions.length > 0) {
            revert RandomTeamSelector__AlreadySelected();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_requestToManager[requestId] = manager;
        s_managerSelections[manager].selectedTeam = SELECTION_ONGOING;
        emit SelectionMade(requestId, manager);
    }

    /**
     * @notice Callback function used by VRF to provide randomness
     * @dev This override is required by VRFConsumerBaseV2Plus. Emits the SelectionRevealed event.
     * @param requestId The request ID of the VRF request
     * @param randomWords The array of random words provided by VRF
     */

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        address manager = s_requestToManager[requestId];
        uint256[] memory teamOptions = new uint256[](i_numWords);

        unchecked {
            for (uint256 i = 0; i < i_numWords; i++) {
                teamOptions[i] = (randomWords[i] % 40) + 1;
            }
        }

        s_managerSelections[manager] = ManagerSelection({
            teamOptions: teamOptions,
            selectedTeam: SELECTION_ONGOING
        });

        emit SelectionRevealed(requestId, teamOptions);
    }

    /**
     * @notice Retrieves the name of the team chosen by a player
     * @dev Requires that a selection has been made. Calls getTeamName from TeamNames.
     * @param player The address of the player whose team name is being requested
     * @return The name of the selected team
     */

    function teamName(address player) public view returns (string memory) {
        ManagerSelection storage selection = s_managerSelections[player];
        if (selection.selectedTeam == 0) {
            revert RandomTeamSelector__SelectionNotMade();
        }
        return getTeamName(selection.selectedTeam);
    }

    /**
     * @notice Retrieves all the team options available for a manager
     * @param manager The address of the manager whose team options are being requested
     * @return An array of team IDs representing the available team options
     */

    function getTeamOptions(
        address manager
    ) public view returns (uint256[] memory) {
        ManagerSelection storage selection = s_managerSelections[manager];
        if (selection.selectedTeam != SELECTION_ONGOING) {
            revert RandomTeamSelector__NoSelectionOptionsAvailable();
        }
        return selection.teamOptions;
    }

    /**
     * @notice Allows a manager to choose a team from their selection options
     * @dev Emits the TeamChosen event.
     * @param teamId The ID of the team being chosen
     */

    function chooseTeam(uint256 teamId) public {
        ManagerSelection storage selection = s_managerSelections[msg.sender];
        if (selection.selectedTeam != SELECTION_ONGOING) {
            revert RandomTeamSelector__SelectionNotMade();
        }

        bool validChoice = false;
        for (uint256 i = 0; i < selection.teamOptions.length; i++) {
            if (selection.teamOptions[i] == teamId) {
                validChoice = true;
                break;
            }
        }

        if (!validChoice) {
            revert RandomTeamSelector__InvalidTeamChoice();
        }

        selection.selectedTeam = teamId;
        emit TeamChosen(msg.sender, teamId);
    }

    /**
     * @notice the following are getter functions used for
     * testing and deployment
     */

    function getRequestToManager(
        uint256 requestId
    ) public view returns (address) {
        return s_requestToManager[requestId];
    }

    function getManagerSelection(
        address manager
    ) public view returns (uint256[] memory teamOptions, uint256 selectedTeam) {
        ManagerSelection storage selection = s_managerSelections[manager];
        return (selection.teamOptions, selection.selectedTeam);
    }
}
