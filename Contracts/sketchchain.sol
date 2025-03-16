// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contract Web3DrawingGame is Ownable, ReentrancyGuard {
//     // Game room structure
//     struct GameRoom {
//         address roomCreator;
//         uint256 wagerAmount;
//         uint256 maxPlayers;
//         uint256 currentPlayerCount;
//         bool isActive;
//         address[] players;
//         mapping(address => PlayerInfo) playerInfos;
//         address winner;
//         uint256 totalPot;
//         uint256 roundStartTime;
//         uint256 currentRound;
//         uint256 totalRounds;
//     }

//     // Player information structure
//     struct PlayerInfo {
//         string name;
//         uint256 points;
//         bool isDrawing;
//         bool hasGuessed;
//     }

//     // Mapping to store game rooms
//     mapping(string => GameRoom) public gameRooms;

//     // Minimum and maximum wager amounts
//     uint256 public constant MIN_WAGER = 1 * 10**18; // 1 USD equivalent in native token
//     uint256 public constant MAX_WAGER = 100 * 10**18; // 100 USD equivalent

//     // Game configuration
//     uint256 public constant ROUND_TIME = 90 seconds; // Combined draw and guess time
//     uint256 public constant MAX_ROUNDS = 3; // Total rounds in a game

//     // Events
//     event RoomCreated(string roomCode, address creator, uint256 wagerAmount, uint256 maxPlayers);
//     event PlayerJoined(string roomCode, address player, string playerName);
//     event GameStarted(string roomCode);
//     event RoundStarted(string roomCode, address currentDrawer, uint256 roundNumber);
//     event PlayerDrawn(string roomCode, address player, string word);
//     event WordGuessed(string roomCode, address guesser, uint256 points);
//     event GameEnded(string roomCode, address winner, uint256 totalPot);
//     event RoomClosed(string roomCode);

//     // Constructor - pass the initial owner (msg.sender in this case)
//     constructor() Ownable(msg.sender) {}

//     // Function to create a game room
//     function createRoom(
//         string memory roomCode,
//         uint256 wagerAmount,
//         uint256 maxPlayers
//     ) external payable nonReentrant {
//         require(gameRooms[roomCode].roomCreator == address(0), "Room already exists");
//         require(maxPlayers > 1, "At least 2 players required");
//         require(wagerAmount >= MIN_WAGER && wagerAmount <= MAX_WAGER, "Invalid wager amount");
//         require(msg.value == wagerAmount, "Incorrect wager amount sent");

//         GameRoom storage newRoom = gameRooms[roomCode];
//         newRoom.roomCreator = msg.sender;
//         newRoom.wagerAmount = wagerAmount;
//         newRoom.maxPlayers = maxPlayers;
//         newRoom.isActive = true;
//         newRoom.players.push(msg.sender);
//         newRoom.currentPlayerCount = 1;
//         newRoom.totalPot = wagerAmount;

//         emit RoomCreated(roomCode, msg.sender, wagerAmount, maxPlayers);
//     }

//     // Function for players to join a game room
//     function joinRoom(string memory roomCode, string memory playerName) external payable nonReentrant {
//         GameRoom storage room = gameRooms[roomCode];
//         require(room.isActive, "Room is not active");
//         require(room.currentPlayerCount < room.maxPlayers, "Room is full");
//         require(msg.value == room.wagerAmount, "Incorrect wager amount");

//         room.players.push(msg.sender);
//         room.playerInfos[msg.sender] = PlayerInfo(playerName, 0, false, false);
//         room.currentPlayerCount++;
//         room.totalPot += msg.value;

//         emit PlayerJoined(roomCode, msg.sender, playerName);
//     }

//     // Function to start the game
//     function startGame(string memory roomCode) external onlyOwner {
//         GameRoom storage room = gameRooms[roomCode];
//         require(room.isActive, "Room is not active");
//         require(room.currentPlayerCount > 1, "Not enough players to start");

//         room.currentRound = 1;
//         room.totalRounds = MAX_ROUNDS;

//         emit GameStarted(roomCode);
//         startRound(roomCode);
//     }

//     // Function to start a round
//     function startRound(string memory roomCode) internal {
//         GameRoom storage room = gameRooms[roomCode];
//         require(room.isActive, "Room is not active");

//         uint256 drawerIndex = (room.currentRound - 1) % room.currentPlayerCount;
//         address currentDrawer = room.players[drawerIndex];
//         room.roundStartTime = block.timestamp;

//         emit RoundStarted(roomCode, currentDrawer, room.currentRound);
//     }

//     // Function to handle the end of the game
//     function endGame(string memory roomCode) external onlyOwner {
//         GameRoom storage room = gameRooms[roomCode];
//         require(room.isActive, "Room is not active");

//         room.isActive = false;
//         address winner = determineWinner(roomCode);
//         room.winner = winner;

//         payable(winner).transfer(room.totalPot);
//         emit GameEnded(roomCode, winner, room.totalPot);
//     }

//     // Helper function to determine the winner
//     function determineWinner(string memory roomCode) internal view returns (address) {
//         GameRoom storage room = gameRooms[roomCode];
//         address winner;
//         uint256 highestPoints = 0;

//         for (uint256 i = 0; i < room.players.length; i++) {
//             address player = room.players[i];
//             uint256 points = room.playerInfos[player].points;

//             if (points > highestPoints) {
//                 highestPoints = points;
//                 winner = player;
//             }
//         }

//         return winner;
//     }

//     // Function to close a room
//     function closeRoom(string memory roomCode) external onlyOwner {
//         GameRoom storage room = gameRooms[roomCode];
//         require(room.isActive, "Room is not active");

//         room.isActive = false;
//         emit RoomClosed(roomCode);
//     }
// }




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Web3DrawingGame is Ownable, ReentrancyGuard {
    // Game room structure
    struct GameRoom {
        address roomCreator;
        uint256 wagerAmount;
        uint256 maxPlayers;
        uint256 currentPlayerCount;
        bool isActive;
        address[] players;
        mapping(address => PlayerInfo) playerInfos;
        address winner;
        uint256 totalPot;
        uint256 roundStartTime;
        uint256 currentRound;
        uint256 totalRounds;
        bool gameStarted;
        bool gameEnded;
    }

    // Player information structure
    struct PlayerInfo {
        string name;
        uint256 points;
        bool isDrawing;
        bool hasGuessed;
    }

    // Mapping to store game rooms
    mapping(string => GameRoom) public gameRooms;
    
    // Public room codes array to keep track of active rooms
    string[] public activeRoomCodes;
    mapping(string => uint256) private roomCodeIndices;

    // Minimum and maximum wager amounts
    uint256 public constant MIN_WAGER = 1 * 10**18; // 1 USD equivalent in native token
    uint256 public constant MAX_WAGER = 100 * 10**18; // 100 USD equivalent

    // Game configuration
    uint256 public constant ROUND_TIME = 90 seconds; // Combined draw and guess time
    uint256 public constant MAX_ROUNDS = 3; // Total rounds in a game

    // Events
    event RoomCreated(string roomCode, address creator, uint256 wagerAmount, uint256 maxPlayers);
    event PlayerJoined(string roomCode, address player, string playerName);
    event GameStarted(string roomCode);
    event RoundStarted(string roomCode, address currentDrawer, uint256 roundNumber);
    event PlayerDrawn(string roomCode, address player, string word);
    event WordGuessed(string roomCode, address guesser, uint256 points);
    event RoundEnded(string roomCode, uint256 roundNumber);
    event GameEnded(string roomCode, address winner, uint256 totalPot);
    event RoomClosed(string roomCode);

    // Constructor - pass the initial owner (msg.sender in this case)
    constructor() Ownable(msg.sender) {}

    // Function to create a game room
    function createRoom(
        string memory roomCode,
        uint256 wagerAmount,
        uint256 maxPlayers,
        string memory playerName
    ) external payable nonReentrant {
        require(bytes(roomCode).length > 0, "Invalid room code");
        require(gameRooms[roomCode].roomCreator == address(0), "Room already exists");
        require(maxPlayers > 1, "At least 2 players required");
        require(wagerAmount >= MIN_WAGER && wagerAmount <= MAX_WAGER, "Invalid wager amount");
        require(msg.value == wagerAmount, "Incorrect wager amount sent");

        GameRoom storage newRoom = gameRooms[roomCode];
        newRoom.roomCreator = msg.sender;
        newRoom.wagerAmount = wagerAmount;
        newRoom.maxPlayers = maxPlayers;
        newRoom.isActive = true;
        newRoom.players.push(msg.sender);
        newRoom.playerInfos[msg.sender] = PlayerInfo(playerName, 0, false, false);
        newRoom.currentPlayerCount = 1;
        newRoom.totalPot = wagerAmount;
        newRoom.gameStarted = false;
        newRoom.gameEnded = false;
        
        // Add to active rooms
        activeRoomCodes.push(roomCode);
        roomCodeIndices[roomCode] = activeRoomCodes.length - 1;

        emit RoomCreated(roomCode, msg.sender, wagerAmount, maxPlayers);
    }

    // Function for players to join a game room
    function joinRoom(string memory roomCode, string memory playerName) external payable nonReentrant {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive, "Room is not active");
        require(!room.gameStarted, "Game has already started");
        require(room.currentPlayerCount < room.maxPlayers, "Room is full");
        require(msg.value == room.wagerAmount, "Incorrect wager amount");
        
        // Check if player is already in the room
        for (uint256 i = 0; i < room.players.length; i++) {
            require(room.players[i] != msg.sender, "Player already in room");
        }

        room.players.push(msg.sender);
        room.playerInfos[msg.sender] = PlayerInfo(playerName, 0, false, false);
        room.currentPlayerCount++;
        room.totalPot += msg.value;

        emit PlayerJoined(roomCode, msg.sender, playerName);
    }

    // Function to start the game (can be called by room creator)
    function startGame(string memory roomCode) external {
        GameRoom storage room = gameRooms[roomCode];
        require(msg.sender == room.roomCreator, "Only room creator can start the game");
        require(room.isActive, "Room is not active");
        require(!room.gameStarted, "Game already started");
        require(room.currentPlayerCount > 1, "Not enough players to start");

        room.currentRound = 1;
        room.totalRounds = MAX_ROUNDS;
        room.gameStarted = true;

        emit GameStarted(roomCode);
        startRound(roomCode);
    }

    // Function to start a round
    function startRound(string memory roomCode) internal {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive && room.gameStarted, "Game not active or not started");
        require(room.currentRound <= room.totalRounds, "All rounds completed");

        // Calculate drawer index based on current round
        uint256 drawerIndex = (room.currentRound - 1) % room.currentPlayerCount;
        address currentDrawer = room.players[drawerIndex];
        
        // Reset player states for new round
        for (uint256 i = 0; i < room.players.length; i++) {
            address player = room.players[i];
            room.playerInfos[player].isDrawing = (player == currentDrawer);
            room.playerInfos[player].hasGuessed = false;
        }
        
        room.roundStartTime = block.timestamp;

        emit RoundStarted(roomCode, currentDrawer, room.currentRound);
    }
    
    // Function to record a word being drawn
    function recordWordDrawn(string memory roomCode, string memory word) external {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive && room.gameStarted, "Game not active or not started");
        require(!room.gameEnded, "Game already ended");
        require(room.playerInfos[msg.sender].isDrawing, "Not your turn to draw");
        
        emit PlayerDrawn(roomCode, msg.sender, word);
    }

    // Function to record a correct guess and award points
    function recordCorrectGuess(string memory roomCode, address guesser, uint256 timeRemaining) external {
        GameRoom storage room = gameRooms[roomCode];
        require(msg.sender == room.roomCreator, "Only room creator can record guesses");
        require(room.isActive && room.gameStarted, "Game not active or not started");
        require(!room.gameEnded, "Game already ended");
        require(!room.playerInfos[guesser].isDrawing, "Drawer cannot guess");
        require(!room.playerInfos[guesser].hasGuessed, "Player already guessed");
        
        // Award points based on time remaining
        uint256 points = calculatePoints(timeRemaining);
        room.playerInfos[guesser].points += points;
        room.playerInfos[guesser].hasGuessed = true;
        
        emit WordGuessed(roomCode, guesser, points);
        
        // Check if all players have guessed
        bool allGuessed = true;
        for (uint256 i = 0; i < room.players.length; i++) {
            address player = room.players[i];
            if (!room.playerInfos[player].isDrawing && !room.playerInfos[player].hasGuessed) {
                allGuessed = false;
                break;
            }
        }
        
        // If all players have guessed or time is up, end the round
        if (allGuessed || (block.timestamp - room.roundStartTime >= ROUND_TIME)) {
            endRound(roomCode);
        }
    }
    
    // Function to end a round manually (if time expires)
    function forceEndRound(string memory roomCode) external {
        GameRoom storage room = gameRooms[roomCode];
        require(msg.sender == room.roomCreator, "Only room creator can force end round");
        require(room.isActive && room.gameStarted, "Game not active or not started");
        require(!room.gameEnded, "Game already ended");
        require(block.timestamp - room.roundStartTime >= ROUND_TIME, "Round time not yet expired");
        
        endRound(roomCode);
    }
    
    // Internal function to end a round
    function endRound(string memory roomCode) internal {
        GameRoom storage room = gameRooms[roomCode];
        
        emit RoundEnded(roomCode, room.currentRound);
        
        // Move to next round or end game
        if (room.currentRound >= room.totalRounds) {
            endGame(roomCode);
        } else {
            room.currentRound++;
            startRound(roomCode);
        }
    }

    // Calculate points based on time remaining (more time = more points)
    function calculatePoints(uint256 timeRemaining) internal pure returns (uint256) {
        // Scale points based on time remaining (80-100 range)
        return 80 + (timeRemaining * 20 / ROUND_TIME);
    }

    // Function to handle the end of the game automatically
    function endGame(string memory roomCode) internal {
        GameRoom storage room = gameRooms[roomCode];
        require(room.isActive && room.gameStarted, "Game not active or not started");
        require(!room.gameEnded, "Game already ended");
        
        room.gameEnded = true;
        
        // Determine winner
        address winner = determineWinner(roomCode);
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

    // Helper function to determine the winner
    function determineWinner(string memory roomCode) internal view returns (address) {
        GameRoom storage room = gameRooms[roomCode];
        address winner;
        uint256 highestPoints = 0;

        for (uint256 i = 0; i < room.players.length; i++) {
            address player = room.players[i];
            uint256 points = room.playerInfos[player].points;

            if (points > highestPoints) {
                highestPoints = points;
                winner = player;
            }
        }

        // In case of a tie, the first player with that score wins
        return winner;
    }
    
    // Function to get player information
    function getPlayerInfo(string memory roomCode, address player) external view returns (
        string memory name,
        uint256 points,
        bool isDrawing,
        bool hasGuessed
    ) {
        GameRoom storage room = gameRooms[roomCode];
        PlayerInfo storage info = room.playerInfos[player];
        return (info.name, info.points, info.isDrawing, info.hasGuessed);
    }
    
    // Function to get all players in a room
    function getRoomPlayers(string memory roomCode) external view returns (address[] memory) {
        return gameRooms[roomCode].players;
    }
    
    // Function to get room details
    function getRoomDetails(string memory roomCode) external view returns (
        address roomCreator,
        uint256 wagerAmount,
        uint256 maxPlayers,
        uint256 currentPlayerCount,
        bool isActive,
        address winner,
        uint256 totalPot,
        uint256 currentRound,
        uint256 totalRounds,
        bool gameStarted,
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
            room.currentRound,
            room.totalRounds,
            room.gameStarted,
            room.gameEnded
        );
    }
    
    // Function to get all active room codes
    function getActiveRoomCodes() external view returns (string[] memory) {
        return activeRoomCodes;
    }

    // Emergency function to withdraw stuck funds (only callable by owner)
    function emergencyWithdraw(string memory roomCode) external onlyOwner {
        GameRoom storage room = gameRooms[roomCode];
        require(!room.isActive || (block.timestamp - room.roundStartTime > 1 days), "Room is still active");
        
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