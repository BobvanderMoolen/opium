// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelGame is ERC721, Ownable {
    enum Color {Red, Green, Blue}

    struct Location {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    struct Player {
        Color color;
        uint256 mintedPixels;
        uint256 paintedPixels;
        mapping(uint256 => Location) pixelLocation;
    }
        
    mapping(address => Player) public players;
    mapping(address => uint256) public playerTokens;

    uint256 public tokenCounter;
    mapping(uint256 => Color) public tokenColors;

    uint256 public maxPlayers;
    uint256 public playersPerGroup;
    uint256 public pixelsPerPlayer;
    bool public gameStarted;


    modifier gameStatus() {
        require(gameStarted, "Game not started yet.");
        _;
    }

    constructor(uint256 _maxPlayers, uint256 _pixelsPerPlayer) ERC721("PixelGame", "PIXEL") {
        maxPlayers = _maxPlayers;
        pixelsPerPlayer = _pixelsPerPlayer;
        playersPerGroup = 3; //_playersPerGroup;
    }

    function getPixelLocations(address playerAddress) public view returns (Location[] memory) {
        uint256 numPixels = players[playerAddress].mintedPixels;
        Location[] memory locations = new Location[](numPixels);

        for (uint256 i = 0; i < numPixels; i++) {
            locations[i] = players[playerAddress].pixelLocation[i];
        }

        return locations;
    }
    function startGame() external onlyOwner {
        require(!gameStarted,"The Game Alread Started");
        gameStarted = true;
    }

    function mint() external gameStatus {
        require(players[msg.sender].mintedPixels < pixelsPerPlayer,"Player already minted all tokens.");
        require(tokenCounter < maxPlayers, "Maximum number of players reached");

        Color randColor = getNextColor();
        players[msg.sender].color = randColor;
        players[msg.sender].mintedPixels++;
        uint256 tokenId = tokenCounter++;
        tokenColors[tokenId] = randColor;
        playerTokens[msg.sender] = tokenId;
        _safeMint(msg.sender, tokenId);
    }

    function paint(uint256 _x, uint256 _y, uint256 _z) external {
        uint256 tokenId = playerTokens[msg.sender];
        require(balanceOf(msg.sender) > 0, "Player does not have a token");
        Location memory location = Location({
            x: _x,
            y: _y,
            z: _z
        });
        players[msg.sender].pixelLocation[players[msg.sender].paintedPixels] = location;
        players[msg.sender].paintedPixels++;
        //delete tokenColors[tokenId];
        playerTokens[msg.sender] = 0;
        _burn(tokenId);
    }

    function getPlayerColor(address player) external view returns (Color) {
        return players[player].color;
    }

    function getNextColor() private view returns (Color) {
        uint256 redCount = 0;
        uint256 greenCount = 0;
        uint256 blueCount = 0;

        for (uint256 i = 0; i < tokenCounter; i++) {
            if (tokenColors[i] == Color.Red) {
                redCount++;
            } else if (tokenColors[i] == Color.Green) {
                greenCount++;
            } else if (tokenColors[i] == Color.Blue) {
                blueCount++;
            }
        }

        require(redCount <= playersPerGroup && greenCount <= playersPerGroup && blueCount <= playersPerGroup,
            "Maximum players reached for all groups");

        Color color;
        uint256 randomNum = uint256(keccak256(abi.encodePacked(msg.sender, tokenCounter, block.timestamp))) % 3;
        if (randomNum == 0 && redCount < playersPerGroup) {
            color = Color.Red;
        } else if (randomNum == 1 && greenCount < playersPerGroup) {
            color = Color.Green;
        } else if (blueCount < playersPerGroup) {
            color = Color.Blue;
        } else if (redCount < playersPerGroup) {
            color = Color.Red;
        } else if (greenCount < playersPerGroup) {
            color = Color.Green;
        } else {
            revert("All groups are full");
        }

        return color;
    }
}

