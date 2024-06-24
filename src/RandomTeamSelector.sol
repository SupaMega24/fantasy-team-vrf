uint256 constant SELECTION_ONGOING = 24; // arbitrary number, no meaning

unchecked {
    for (uint256 i = 0; i < i_numWords; i++) {
        teamOptions[i] = (randomWords[i] % 40) + 1;
    }
}

contract RandomTeamSelector is VRFConsumerBaseV2Plus, TeamNames, Ownable {
    function chooseTeam(uint256 teamId) public nonReentrant {
        ManagerSelection storage selection = s_managerSelections[msg.sender];
        if (selection.selectedTeam != SELECTION_ONGOING) {
            revert RandomTeamSelector__InvalidTeamChoice();
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
}