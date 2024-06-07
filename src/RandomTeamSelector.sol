// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Random Team Selector/Fantasy
 * @author Charlie J
 * @notice This contract requests randomness. It is strictly for entertainment.
 *         The team names are not real and have no association with an real professional teams or otherwise.
 * @dev This contract inherits
 */

contract RandomTeamSelector is VRFConsumerBaseV2Plus {
    // Errors
    error RandomTeamSelector__All_ready_selected();

    // State Variables
    uint256 private constant SELECTION_ONGOING = 24; // arbitray number, no meaning
    uint256 public s_subscriptionId;

    // Sepolia coordinator. For other networks,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    address public vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    bytes32 public s_keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 40000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    mapping(uint256 => address) private s_managers;
    mapping(address => uint256) private s_results;

    // Events
    event SelectionMade(uint256 indexed requestId, address indexed manager);
    event SelectionRevealed(
        uint256 indexed requestId,
        uint256 indexed teamValue
    );

    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
    }

    function getRandomTeamName(
        address manager
    ) public onlyOwner returns (uint256 requestId) {
        // Revert if manager has already selected
        if (s_results[manager] != 0) {
            revert RandomTeamSelector__All_ready_selected();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_managers[requestId] = manager;
        s_results[manager] = SELECTION_ONGOING;
        emit SelectionMade(requestId, manager);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number to this contract.
     * @dev The VRF Coordinator along with the parent contract (VRFConsumerBaseV2Plus) ensure randomness
     *      Only verified responses are sent to this function     *
     */

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 teamValue = (randomWords[0] % 20) + 1;
        s_results[s_managers[requestId]] = teamValue;
        emit SelectionRevealed(requestId, teamValue);
    }

    /**
     * @notice get the team name once randome selection is made
     * @dev set customer revert logic and return the getter function
     *
     */
    function teamName(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Selection not made");
        require(
            s_results[player] != SELECTION_ONGOING,
            "Selection in progress"
        );
        return getTeamName(s_results[player]);
    }

    /**
     * @notice Get team name from the id
     * @param id uint256
     * @return team name string
     * @dev These names are an initial list.
     * They are based largely on mythical or fantasy creatures
     * Feel free to change or expand on the list
     * @param id uint256
     */

    function getTeamName(uint256 id) private pure returns (string memory) {
        string[40] memory teamNames = [
            "Phoenix",
            "Seraphs",
            "Revenants",
            "Leviathans",
            "Frostbite",
            "Zephyrs",
            "Luminaries",
            "Spectres",
            "Tempests",
            "Juggernauts",
            "Nightmares",
            "Thunderbolts",
            "Wyverns",
            "Paladins",
            "Arcanes",
            "Celestials",
            "Drakes",
            "Rampage",
            "Sentinels",
            "Behemoths",
            "Griffins",
            "Minotaurs",
            "Hydras",
            "Chimera",
            "Phoenixes",
            "Basilisks",
            "Manticores",
            "Krakens",
            "Nymphs",
            "Wendigos",
            "Gorgons",
            "Centaurs",
            "Djinns",
            "Valkyries",
            "Banshees",
            "Lycans",
            "Sylphs",
            "Dryads",
            "Sphinxes",
            "Hippogriffs"
        ];
        return teamNames[id - 1];
    }
}
