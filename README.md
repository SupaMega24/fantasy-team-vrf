# Random Team Name Selector Smart Contract

## Overview
The Random Team Selector is a Solidity smart contract designed to integrate with Chainlink's Verifiable Random Function (VRF) to provide verifiable randomness in the selection of team names. This contract is part of a decentralized application that connects shoe brands with customers and rewards users for their health activity.

## Features
- **Random Team Name Requests**: Allows the contract owner to initiate a request for random team names for a manager.
- **Chainlink VRF Integration**: Utilizes Chainlink VRF to ensure that the randomness provided for the team name selection is provably fair and tamper-proof.
- **Team Selection Storage**: Records the manager's chosen team name on-chain, ensuring transparency and immutability of the selection.
- **Manager Interaction**: Provides functions for managers to retrieve their team options and make their selection.

## Functions
- `requestRandomTeamNames(address manager)`: Initiates the random team name selection process for the provided manager address.
- `fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)`: Callback function used by Chainlink VRF to provide the random words.
- `getTeamOptions(address manager)`: Retrieves the available team options for the provided manager address.
- `chooseTeam(uint256 teamId)`: Allows a manager to choose a team from the provided options.
- `teamName(address player)`: Retrieves the name of the team chosen by the provided player address.

## Events
- `SelectionMade`: Emitted when a selection process is initiated.
- `SelectionRevealed`: Emitted when the random selection is revealed.
- `TeamChosen`: Emitted when a manager makes their team choice.

## Development Setup
To set up the development environment for the Random Team Selector smart contract, follow these steps:

1. WILL ADD LATER:


## Frontend Integration
The smart contract is designed to work with a frontend interface that displays the team options to the user and captures their selection. The frontend should interact with the smart contract using a web3 provider like MetaMask.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

