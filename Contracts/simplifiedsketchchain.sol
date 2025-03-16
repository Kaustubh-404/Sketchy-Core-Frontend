// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Web3DrawingGame
 * @dev A blockchain-based drawing and guessing game where players compete to win a prize pool
 */
contract Web3DrawingGame is Ownable, ReentrancyGuard {
    // Game room structure
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

    // Mapping to store game rooms
    mapping(string => GameRoom) public gameRooms;
    
    // Public room codes array to keep track of active rooms
    string[] public activeRoomCodes;
    mapping(string => uint256) private roomCodeIndices;

    // Minimum and maximum wager amounts
    uint256 public constant MIN_WAGER = 10**16; // 0.01 tCORE minimum
    uint256 public constant MAX_WAGER = 100 * 10**18; // 100 tCORE maximum

    // Admin address to manage game state (typically your backend)
    address public gameManager;

    // Events
    event RoomCreated(string roomCode, address creator, uint256 wagerAmount, uint256 maxPlayers);
    event PlayerJoined(string roomCode, address player, string playerName);
    event GameStarted(string roomCode);
    event GameEnded(string roomCode, address winner, uint256 totalPot);
    event RoomClosed(string roomCode);

    modifier onlyGameManager() {
        require(msg.sender == gameManager || msg.sender == owner(), "Only game manager can call this function");
        _;
    }

    // Constructor - pass the initial owner (msg.sender in this case)
    constructor() Ownable(msg.sender) {
        gameManager = msg.sender; // Set initial game manager to the owner
    }

    // Set game manager address (your backend service address)
    function setGameManager(address _gameManager) external onlyOwner {
        gameManager = _gameManager;
    }

    /**
     * @dev Create a new game room
     * @param roomCode Unique code for the room
     * @param wagerAmount Amount each player needs to pay to join
     * @param maxPlayers Maximum number of players allowed in the room
     */
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
        
        // Use generic player name
        string memory playerName = string(abi.encodePacked("Player ", toAsciiString(msg.sender)));
        newRoom.playerNames[msg.sender] = playerName;
        
        newRoom.currentPlayerCount = 1;
        newRoom.totalPot = wagerAmount;
        newRoom.gameEnded = false;
        
        // Add to active rooms
        activeRoomCodes.push(roomCode);
        roomCodeIndices[roomCode] = activeRoomCodes.length - 1;

        emit RoomCreated(roomCode, msg.sender, wagerAmount, maxPlayers);
    }

    /**
     * @dev Create a new game room (overloaded to accept player name)
     * @param roomCode Unique code for the room
     * @param wagerAmount Amount each player needs to pay to join
     * @param maxPlayers Maximum number of players allowed in the room
     * @param playerName Name of the player creating the room
     */
    function createRoom(
        string memory roomCode,
        uint256 wagerAmount,
        uint256 maxPlayers,
        string memory playerName
    ) external payable nonReentrant {
        require(bytes(roomCode).length > 0, "Invalid room code");
        require(bytes(playerName).length > 0, "Invalid player name");
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
        newRoom.playerNames[msg.sender] = playerName;
        newRoom.currentPlayerCount = 1;
        newRoom.totalPot = wagerAmount;
        newRoom.gameEnded = false;
        
        // Add to active rooms
        activeRoomCodes.push(roomCode);
        roomCodeIndices[roomCode] = activeRoomCodes.length - 1;

        emit RoomCreated(roomCode, msg.sender, wagerAmount, maxPlayers);
    }

    /**
     * @dev Join an existing game room
     * @param roomCode Code of the room to join
     */
    function joinRoom(string memory roomCode) external payable nonReentrant {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameEnded, "Game has already ended");
        require(room.currentPlayerCount < room.maxPlayers, "Room is full");
        require(msg.value == room.wagerAmount, "Incorrect wager amount");
        
        // Check if player is already in the room
        for (uint256 i = 0; i < room.players.length; i++) {
            require(room.players[i] != msg.sender, "Player already in room");
        }

        room.players.push(msg.sender);
        
        // Use generic player name
        string memory playerName = string(abi.encodePacked("Player ", toAsciiString(msg.sender)));
        room.playerNames[msg.sender] = playerName;
        
        room.currentPlayerCount++;
        room.totalPot += msg.value;

        emit PlayerJoined(roomCode, msg.sender, playerName);
    }

    /**
     * @dev Join an existing game room (overloaded to accept player name)
     * @param roomCode Code of the room to join
     * @param playerName Name of the player joining the room
     */
    function joinRoom(string memory roomCode, string memory playerName) external payable nonReentrant {
        require(bytes(playerName).length > 0, "Invalid player name");
        
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameEnded, "Game has already ended");
        require(room.currentPlayerCount < room.maxPlayers, "Room is full");
        require(msg.value == room.wagerAmount, "Incorrect wager amount");
        
        // Check if player is already in the room
        for (uint256 i = 0; i < room.players.length; i++) {
            require(room.players[i] != msg.sender, "Player already in room");
        }

        room.players.push(msg.sender);
        room.playerNames[msg.sender] = playerName;
        room.currentPlayerCount++;
        room.totalPot += msg.value;

        emit PlayerJoined(roomCode, msg.sender, playerName);
    }

    /**
     * @dev End the game and distribute the prize to the winner
     * @param roomCode Code of the room
     * @param winner Address of the winner determined by the backend
     */
    function endGame(string memory roomCode, address winner) external onlyGameManager nonReentrant {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameEnded, "Game already ended");
        
        // Verify winner is a participant
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
        
        // Transfer the pot to the winner
        uint256 totalPot = room.totalPot;
        room.totalPot = 0;
        
        // Mark room as inactive
        room.isActive = false;
        
        // Remove from active rooms
        uint256 indexToDelete = roomCodeIndices[roomCode];
        uint256 lastIndex = activeRoomCodes.length - 1;
        
        if (indexToDelete != lastIndex) {
            string memory lastRoom = activeRoomCodes[lastIndex];
            activeRoomCodes[indexToDelete] = lastRoom;
            roomCodeIndices[lastRoom] = indexToDelete;
        }
        
        activeRoomCodes.pop();
        delete roomCodeIndices[roomCode];
        
        // Transfer funds to winner
        payable(winner).transfer(totalPot);
        
        emit GameEnded(roomCode, winner, totalPot);
    }
    
    /**
     * @dev Get player name
     * @param roomCode Code of the room
     * @param player Address of the player
     * @return Player's name
     */
    function getPlayerName(string memory roomCode, address player) external view returns (string memory) {
        GameRoom storage room = gameRooms[roomCode];
        return room.playerNames[player];
    }
    
    /**
     * @dev Get all players in a room
     * @param roomCode Code of the room
     * @return Array of player addresses
     */
    function getRoomPlayers(string memory roomCode) external view returns (address[] memory) {
        return gameRooms[roomCode].players;
    }
    
    
    function getRoomDetails(string memory roomCode) external view returns (
        address roomCreator,
        uint256 wagerAmount,
        uint256 maxPlayers,
        uint256 currentPlayerCount,
        bool isActive,
        address winner,
        uint256 totalPot,
        bool gameEnded
    ) {
        GameRoom storage room = gameRooms[roomCode];
        return (
            room.roomCreator,
            room.wagerAmount,
            room.maxPlayers,
            room.currentPlayerCount,
            room.isActive,
            room.winner,
            room.totalPot,
            room.gameEnded
        );
    }
    
    /**
     * @dev Get all active room codes
     * @return Array of active room codes
     */
    function getActiveRoomCodes() external view returns (string[] memory) {
        return activeRoomCodes;
    }

    /**
     * @dev Convert an address to a string
     * @param _addr Address to convert
     * @return String representation of the address
     */
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
    
    /**
     * @dev Convert a byte to a character
     * @param b Byte to convert
     * @return Character representation of the byte
     */
    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Emergency function to withdraw stuck funds (only callable by owner)
     * @param roomCode Code of the room
     */
    function emergencyWithdraw(string memory roomCode) external onlyOwner {
        GameRoom storage room = gameRooms[roomCode];
        require(!room.isActive || room.gameEnded, "Room is still active");
        
        uint256 amount = room.totalPot;
        room.totalPot = 0;
        room.isActive = false;
        
        // Remove from active rooms if needed
        if (roomCodeIndices[roomCode] > 0 || (activeRoomCodes.length > 0 && keccak256(bytes(activeRoomCodes[0])) == keccak256(bytes(roomCode)))) {
            uint256 indexToDelete = roomCodeIndices[roomCode];
            uint256 lastIndex = activeRoomCodes.length - 1;
            
            if (indexToDelete != lastIndex) {
                string memory lastRoom = activeRoomCodes[lastIndex];
                activeRoomCodes[indexToDelete] = lastRoom;
                roomCodeIndices[lastRoom] = indexToDelete;
            }
            
            activeRoomCodes.pop();
            delete roomCodeIndices[roomCode];
        }
        
        payable(owner()).transfer(amount);
        
        emit RoomClosed(roomCode);
    }
}