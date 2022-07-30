// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Luchador.sol";

contract Battle is Ownable, VRFConsumerBaseV2 {
  using SafeMath for uint256;
  using SafeMath for uint8;

  uint256 private constant ROLL_IN_PROGRESS = 42;
  /** ------------- Constants ------------- */
  uint256 public constant BATTLE_PREPARE_TIME = 30 * 3600; // 30 min
  address public multisig = 0x5FFCc9f5d9ee5E057878F7A4D0DB8cb6d0598b50;
  /// @notice Battle Register Amount - Nacho Token
  uint256[7] public registerAmount = [5 * 1e18, 12 * 1e18, 20 * 1e18, 30 * 1e18, 60 * 1e18, 120 * 1e18, 20 * 1e18];
  /// @notice Battle Prize Amount - Nbond Token
  uint256[7] public prizeAmount = [20 * 1e18, 50 * 1e18, 80 * 1e18, 100 * 1e18, 200 * 1e18, 500 * 1e18, 500 * 1e18];
  /// @notice Dice Critical Random number for win/lose
  uint8 CRITICAL_DICE_WIN = 20;
  uint8 CRITICAL_DICE_LOSE = 1;

  /// @notice Fee interest
  uint8 public FEE_INTEREST = 5;

  /** ------------- Data ------------- */

  enum GameStatus {
    Started,
    // Registered,
    Finished
  }

  enum VersusRoundStatus {
    WinFirst,
    WinSecond,
    Tie
  }

  struct SpectatorOverview {
    bool bet; // True -> Player 1 bet , False - Player 2 bet
    uint256 betAmount;
    address account;
  }

  /** --------------- State ---------------- */

  // address
  Luchador public luchador; // luchador NFT token address
  IERC20 public nachoToken; // nacho ERC20 token address
  IERC20 public nbondToken; // nbond ERC20 token address

  // battle status
  uint256 public battleStartTime;
  GameStatus public versusGameStatus;
  GameStatus public royalGameStatus;

  /// Head to Head Match Registers
  uint256[2][6] public versusFighters;
  /// Battle Royale Registers
  uint256[16] public royaleFighters;
  // Versus Battle Results
  VersusRoundStatus[7][6] public versusRoomRoundResult; // True -> Player 1 win , False - Player 2 win
  VersusRoundStatus[6] public versusRoomResult; // True -> Player 1 win , False - Player 2 win

  /// Battle Royale Spectators
  // mapping(uint256 => mapping(address => SpectatorOverview)) public spectators;
  SpectatorOverview[][6] public spectators;
  /// Wager Total Amount per room
  uint256[2][6] public wagerTotalAmount;

  /// Random Number Vairable
  mapping(uint256 => address) private s_rollers;
  mapping(address => uint256) private s_results;

  /// @notice Chainlink variable for get random number
  VRFCoordinatorV2Interface public coordinator = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
  uint64 public subscriptionId = 1175;
  bytes32 public keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 public callbackGasLimit = 200000;
  uint16 public requestConfirmations = 3;
  uint32 public constant numWords = 5;

  /** ------------ Constructor ----------- */
  constructor(
    address _nachoToken,
    address _nbondToken,
    address _luchadorAddr,
    address _vrfCoordinator, // 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
    bytes32 _keyHash, // 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
    uint64 _subscriptionId // 1175
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    luchador = Luchador(_luchadorAddr);
    nachoToken = IERC20(_nachoToken);
    nbondToken = IERC20(_nbondToken);

    coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    keyHash = _keyHash;
    subscriptionId = _subscriptionId;
  }

  /* ========== MUTATIVE FUNCTIONS - register ========== */

  /// @notice Register NFTs for Head to Head Match
  function registerVersusBattle(uint256 _roomId, uint256 _tokenId) external {
    // Check if battle is started
    require(block.timestamp > battleStartTime, "Battle Not Started");
    require(_roomId >= 0 && _roomId <= 6, "Invalid Room ID");
    // Check token exists and user is owner of this token
    require(luchador.doesOwnLuchador(msg.sender, _tokenId), "Not owned this NFT");
    // Check if NFT is not on sale now
    require(!luchador.isLuchadorForSale(_tokenId), "NFT is on the sale");
    // Check the NFT requires the weight
    require(luchador.luchadoresWeight(_tokenId) >= _roomId * 10 + 60 && luchador.luchadoresWeight(_tokenId) <= _roomId * 10 + 70, "Not required Weight");
    // Check if 2 positions are already registered
    require(versusFighters[_roomId][1] == 0, "Fully Registered");

    nachoToken.transferFrom(msg.sender, multisig, registerAmount[_roomId]);

    versusGameStatus == GameStatus.Started;

    if (versusFighters[_roomId][0] == 0)
      // Set first register
      versusFighters[_roomId][0] = _tokenId;
      // Set second register
    else versusFighters[_roomId][1] = _tokenId;
  }

  function fightVersusBattle() public onlyOwner {
    // Check if Versus battle is started
    for (uint8 roomId = 0; roomId < 6; roomId++) {
      require(versusFighters[roomId][0] != 0 && versusFighters[roomId][1] != 0, "Not Fully Registered");
    }

    // versusGameStatus == GameStatus.Registered;

    uint8 roundId;
    uint8 playerId;
    uint256[20][2] memory playerAttributes;
    uint256[2] memory roundMax;
    uint256[2] memory randomNumber;

    for (uint8 roomId = 0; roomId < 6; roomId++) {
      uint8 _versusRoomResult = 10;
      for (roundId = 0; roundId < 7; roundId++) {
        // randomNumber[0] = getRandomNumber();
        // randomNumber[1] = getRandomNumber();

        // randomNumber[0] = roundId + 14;
        // randomNumber[1] = roundId + 16;
        if (randomNumber[0] == CRITICAL_DICE_WIN || randomNumber[1] == CRITICAL_DICE_LOSE) {
          versusRoomRoundResult[roomId][roundId] = VersusRoundStatus.WinFirst;
          _versusRoomResult += 1;
        } else if (randomNumber[0] == CRITICAL_DICE_LOSE || randomNumber[1] == CRITICAL_DICE_WIN) {
          versusRoomRoundResult[roomId][roundId] = VersusRoundStatus.WinSecond;
          _versusRoomResult -= 1;
        } else {
          for (playerId = 0; playerId < 2; playerId++) {
            playerAttributes[playerId] = luchador.getAllLuchadorAttributes(versusFighters[roomId][playerId]);
            roundMax[playerId] =
              (playerAttributes[playerId][0] + 1) *
              (playerAttributes[playerId][1] + 1) *
              (playerAttributes[playerId][2] + 1) *
              randomNumber[playerId];
          }

          if (roundMax[0] > roundMax[1]) {
            versusRoomRoundResult[roomId][roundId] = VersusRoundStatus.WinFirst;
            _versusRoomResult += 1;
          } else if (roundMax[0] < roundMax[1]) {
            versusRoomRoundResult[roomId][roundId] = VersusRoundStatus.WinSecond;
            _versusRoomResult -= 1;
          } else {
            versusRoomRoundResult[roomId][roundId] = VersusRoundStatus.Tie;
          }
        }
        if (_versusRoomResult > 10) versusRoomResult[roomId] = VersusRoundStatus.WinFirst;
        else if (_versusRoomResult < 10) versusRoomResult[roomId] = VersusRoundStatus.WinSecond;
        else versusRoomResult[roomId] = VersusRoundStatus.Tie;
      }
    }
    versusGameStatus = GameStatus.Finished;
    // earnSpectaterWager();
  }

  /* ========== MUTATIVE FUNCTIONS - spectator ========== */

  /// @notice Spectators wager to battle
  function wagerBattle(
    uint256 _roomId,
    bool _bet,
    uint256 _amount
  ) external {
    nachoToken.transferFrom(msg.sender, multisig, _amount);
    SpectatorOverview memory _overview;
    _overview.bet = _bet;
    _overview.betAmount = _amount;
    _overview.account = msg.sender;
    spectators[_roomId].push(_overview);
    if (_bet) wagerTotalAmount[_roomId][1] += _amount;
    else wagerTotalAmount[_roomId][0] += _amount;
  }

  /// @notice Spectators wager to battle
  function earnSpectaterWager() internal {
    require(versusGameStatus == GameStatus.Finished, "Battle not finished");
    for (uint8 roomId = 0; roomId < 6; roomId++) {
      if (versusRoomResult[roomId] != VersusRoundStatus.Tie) {
        for (uint8 spectatorId = 0; spectatorId < spectators[roomId].length; spectatorId++) {
          if (spectators[roomId][spectatorId].bet && versusRoomResult[roomId] == VersusRoundStatus.WinFirst) {
            uint256 spectatorPercent;
            if (spectators[roomId][spectatorId].bet) spectatorPercent = spectators[roomId][spectatorId].betAmount / wagerTotalAmount[roomId][1];
            else spectatorPercent = spectators[roomId][spectatorId].betAmount / wagerTotalAmount[roomId][0];
            nbondToken.transfer(spectators[roomId][spectatorId].account, ((100 - FEE_INTEREST) * spectatorPercent * prizeAmount[roomId]) / 10000);
          }
        }
      }
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  /**
   * @notice set battle start time
   */
  function setBattleStartTime(uint256 _battleStartTime) external onlyOwner {
    battleStartTime = _battleStartTime;
  }

  /**
   * @notice set register amount
   */
  function setRegisterAmount(uint256 _roomId, uint256 _amount) external onlyOwner {
    registerAmount[_roomId] = _amount;
  }

  /**
   * @notice set prize amount
   */
  function setPrizeAmount(uint256 _roomId, uint256 _amount) external onlyOwner {
    prizeAmount[_roomId] = _amount;
  }

  function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
    subscriptionId = _subscriptionId;
  }

  function setKeyHash(bytes32 _keyHash) external onlyOwner {
    keyHash = _keyHash;
  }

  function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
    callbackGasLimit = _callbackGasLimit;
  }

  function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
    requestConfirmations = _requestConfirmations;
  }

  /* ========== INTERNALS ========== */

  function getRandomNumber(address roller) public returns (uint256 requestID) {
    require(keyHash != bytes32(0), "Must have valid key hash");

    requestID = coordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    s_rollers[requestID] = roller;
    s_results[roller] = ROLL_IN_PROGRESS;
    // emit DiceRolled(requestId, roller);

    require(keyHash != bytes32(0), "Must have valid key hash");

    requestID = coordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
  }

  /**
   * @notice Callback function used by ChainLink's VRF v2 Coordinator
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}
}
