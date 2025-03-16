// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Web3DrawingGame is Ownable, ReentrancyGuard {
    struct GameRoom {
        address roomCreator;
        uint256 wagerAmount;
        uint256 maxPlayers;
        uint256 currentPlayerCount;
        bool isActive;
        address[] players;
        mapping(address => string) playerNames;
        address winner;
        uint256 totalPot;
        bool gameEnded;
    }

    mapping(string => GameRoom) public gameRooms;
    string[] public activeRoomCodes;
    mapping(string => uint256) private roomCodeIndices;

    uint256 public constant MIN_WAGER = 10**16; // 0.01 tCORE minimum
    uint256 public constant MAX_WAGER = 100 * 10**18; // 100 tCORE maximum

    address public gameManager;

    event RoomCreated(string roomCode, address creator, uint256 wagerAmount, uint256 maxPlayers);
    event PlayerJoined(string roomCode, address player, string playerName);
    event GameStarted(string roomCode);
    event GameEnded(string roomCode, address winner, uint256 totalPot);
    event RoomClosed(string roomCode);

    modifier onlyGameManager() {
        require(msg.sender == gameManager || msg.sender == owner(), "Only game manager can call this function");
        _;
    }

    constructor() Ownable(msg.sender) {
        gameManager = msg.sender;
    }

    function setGameManager(address _gameManager) external onlyOwner {
        gameManager = _gameManager;
    }

    function createRoom(
        string memory roomCode,
        uint256 wagerAmount,
        uint256 maxPlayers
    ) external payable nonReentrant {
        require(bytes(roomCode).length > 0, "Invalid room code");
        require(gameRooms[roomCode].roomCreator == address(0), "Room already exists");
        require(maxPlayers > 1 && maxPlayers <= 8, "Players must be between 2-8");
        require(wagerAmount >= MIN_WAGER && wagerAmount <= MAX_WAGER, "Invalid wager amount");
        require(msg.value == wagerAmount, "Incorrect wager amount sent");

        GameRoom storage newRoom = gameRooms[roomCode];
        newRoom.roomCreator = msg.sender;
        newRoom.wagerAmount = wagerAmount;
        newRoom.maxPlayers = maxPlayers;
        newRoom.isActive = true;
        newRoom.players.push(msg.sender);
        newRoom.playerNames[msg.sender] = string(abi.encodePacked("Player ", toAsciiString(msg.sender)));
        newRoom.currentPlayerCount = 1;
        newRoom.totalPot = wagerAmount;
        newRoom.gameEnded = false;

        activeRoomCodes.push(roomCode);
        roomCodeIndices[roomCode] = activeRoomCodes.length - 1;

        emit RoomCreated(roomCode, msg.sender, wagerAmount, maxPlayers);
    }

    function joinRoom(string memory roomCode, string memory playerName) external payable nonReentrant {
        require(bytes(playerName).length > 0, "Invalid player name");

        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameEnded, "Game has already ended");
        require(room.currentPlayerCount < room.maxPlayers, "Room is full");
        require(msg.value == room.wagerAmount, "Incorrect wager amount");

        for (uint256 i = 0; i < room.players.length; i++) {
            require(room.players[i] != msg.sender, "Player already in room");
        }

        room.players.push(msg.sender);
        room.playerNames[msg.sender] = playerName;
        room.currentPlayerCount++;
        room.totalPot += msg.value;

        emit PlayerJoined(roomCode, msg.sender, playerName);
    }

    function endGame(string memory roomCode, address winner) external onlyGameManager nonReentrant {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameEnded, "Game already ended");

        bool isParticipant = false;
        for (uint256 i = 0; i < room.players.length; i++) {
            if (room.players[i] == winner) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "Winner must be a participant");

        room.gameEnded = true;
        room.winner = winner;
        uint256 totalPot = room.totalPot;
        room.totalPot = 0;
        room.isActive = false;

        uint256 indexToDelete = roomCodeIndices[roomCode];
        uint256 lastIndex = activeRoomCodes.length - 1;
        if (indexToDelete != lastIndex) {
            string memory lastRoom = activeRoomCodes[lastIndex];
            activeRoomCodes[indexToDelete] = lastRoom;
            roomCodeIndices[lastRoom] = indexToDelete;
        }
        activeRoomCodes.pop();
        delete roomCodeIndices[roomCode];

        payable(winner).transfer(totalPot);

        emit GameEnded(roomCode, winner, totalPot);
    }

    function getActiveRoomCodes() external view returns (string[] memory) {
        return activeRoomCodes;
    }

    function toAsciiString(address _addr) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2+2*i] = char(hi);
            s[2+2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
