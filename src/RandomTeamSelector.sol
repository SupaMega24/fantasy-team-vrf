// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing Chainlink's VRFConsumerBaseV2Plus for verifiable randomness
// Importing Chainlink's VRFV2PlusClient library for VRF requests
// Importing the TeamNames contract which contains team names data
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {TeamNames} from "./TeamNames.sol";

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
    uint256 public s_subscriptionId; // Subscription ID for the Chainlink VRF service

    // Sepolia vrfCoordinator
    // For other networks,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    address public vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    // Sepolia Gas Lane
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    bytes32 public s_keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 300000; // Gas limit for the VRF callback function
    uint16 public requestConfirmations = 3; // Number of confirmations required for the VRF request
    uint32 public numWords = 3; // Request 3 random words

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
     * @param subscriptionId The Chainlink VRF subscription ID
     */

    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
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
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
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
        uint256[] memory teamOptions = new uint256[](numWords);

        for (uint256 i = 0; i < numWords; i++) {
            teamOptions[i] = (randomWords[i] % 40) + 1;
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
        require(
            selection.selectedTeam == SELECTION_ONGOING,
            "Selection process not ongoing or already completed."
        );

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

    // function getManagerSelection(
    //     address manager
    // ) public view returns (uint256[] memory, uint256) {
    //     ManagerSelection storage selection = s_managerSelections[manager];
    //     return (selection.teamOptions, selection.selectedTeam);
    // }
}
