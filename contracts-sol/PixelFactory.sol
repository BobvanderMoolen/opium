// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PixelGame.sol";

contract PixelFactory {
    address[] public deployedGames;

    function createPixelGame(uint256 maxPlayers, uint256 pixelsPerPlayer) external {
        PixelGame newGame = new PixelGame(maxPlayers, pixelsPerPlayer);
        newGame.transferOwnership(msg.sender);
        deployedGames.push(address(newGame));
    }

    function getDeployedGames() external view returns (address[] memory) {
        return deployedGames;
    }
}
