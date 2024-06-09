// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Team Names List
 * @author Charlie J
 * @notice Get team name from the id
 * @dev These names are an initial list.
 * They are based largely on mythical or fantasy creatures
 * Feel free to change or expand on the list
 *
 */

contract TeamNames {
    function getTeamName(uint256 id) public pure returns (string memory) {
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
            "Legends",
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
        require(id > 0 && id <= teamNames.length, "Invalid team ID");
        return teamNames[id - 1];
    }
}
