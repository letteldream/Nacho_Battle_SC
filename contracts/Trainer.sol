// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Luchador.sol";

contract Trainer is ITrainer, Ownable {
  uint256 public constant MAX_SPOTS = 100;

  mapping(address => bool) public trainersOwners;
  mapping(address => uint256) public trainersLevel;
  mapping(address => uint256) public trainersLuchadorCap;
  mapping(address => uint256) public trainersLuchadorCount;
  mapping(address => uint256[MAX_SPOTS]) public trainersLuchadores;
  mapping(address => address[MAX_SPOTS]) public trainersUserWhitelist;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address public luchador;
  address public multisig = 0x5FFCc9f5d9ee5E057878F7A4D0DB8cb6d0598b50;

  ERC20Burnable public nacho = ERC20Burnable(0xcD86152047e800d67BDf00A4c635A8B6C0e5C4c2);

  uint256 public unlockCost = 5 ether;
  uint256 public upgradeBaseCost = 1 ether;

  constructor(address _luchador) {
    luchador = _luchador;
  }

  function setCost(uint256 change) external onlyOwner {
    unlockCost = change;
  }

  function setUpgradeBaseCost(uint256 change) external onlyOwner {
    upgradeBaseCost = change;
  }

  function unlock() external {
    nacho.transferFrom(msg.sender, address(this), unlockCost);
    nacho.burn(unlockCost);

    trainersOwners[msg.sender] = true;
    trainersLevel[msg.sender] = 1;
    trainersLuchadorCap[msg.sender] = 1;
  }

  function upgrade() external {
    uint256 currentLevel = trainersLevel[msg.sender];
    require(currentLevel < 10, "Trainer already at max level");

    uint256 cost = (10**currentLevel) * upgradeBaseCost;
    nacho.transferFrom(msg.sender, address(this), cost);
    nacho.burn(cost);

    currentLevel++;
    trainersLevel[msg.sender] = currentLevel;

    if (currentLevel < 5) {
      trainersLuchadorCap[msg.sender] = currentLevel;
    } else {
      trainersLuchadorCap[msg.sender] = currentLevel**2;
    }
  }

  function whitelistUser(uint256 slot, address user) external {
    require(trainersOwners[msg.sender], "Sender not a trainer owner");
    trainersUserWhitelist[msg.sender][slot] = user;
  }

  function removeWhitelistedUser(uint256 slot) external {
    require(trainersOwners[msg.sender], "Sender not a trainer owner");

    address luchadorOwner = trainersUserWhitelist[msg.sender][slot];
    trainersUserWhitelist[msg.sender][slot] = address(0);

    uint256 length = trainersLuchadores[msg.sender].length;
    for (uint256 i = 0; i < length; i++) {
      uint256 luchadorId = trainersLuchadores[msg.sender][i];
      if (Luchador(luchador).doesOwnLuchador(luchadorOwner, luchadorId)) {
        Luchador(luchador).removeFromTrainer(luchadorId);
      }
    }
  }

  function luchadoresInTrainer(address trainerOwner) public view returns (uint256[MAX_SPOTS] memory) {
    return trainersLuchadores[trainerOwner];
  }

  function trainerWhitelist(address trainerOwner) public view returns (address[MAX_SPOTS] memory) {
    return trainersUserWhitelist[trainerOwner];
  }

  function isLuchadorInTrainer(uint256 luchadorId, address trainerOwner) public view returns (bool) {
    uint256 length = trainersLuchadores[trainerOwner].length;
    for (uint256 i = 0; i < length; i++) {
      if (trainersLuchadores[trainerOwner][i] == luchadorId) {
        return true;
      }
    }

    return false;
  }

  function checkAllowed(address trainerOwner, address luchadorOwner) public view returns (bool) {
    if (!(trainersOwners[trainerOwner])) {
      return false;
    }

    if (luchadorOwner == trainerOwner) {
      return true;
    }

    uint256 length = trainersUserWhitelist[trainerOwner].length;
    for (uint256 i = 0; i < length; ++i) {
      if (trainersUserWhitelist[trainerOwner][i] == luchadorOwner) {
        return true;
      }
    }

    return false;
  }

  function placeLuchador(address trainerOwner, uint256 luchadorId) public {
    require(msg.sender == luchador, "Only the luchador contract can place luchadores");
    require(trainersLuchadorCount[trainerOwner] < trainersLuchadorCap[trainerOwner], "Not enough luchador cap");

    uint256 length = trainersLuchadores[trainerOwner].length;
    for (uint256 i = 0; i < length; i++) {
      if (trainersLuchadores[trainerOwner][i] == 0) {
        trainersLuchadores[trainerOwner][i] = luchadorId;
        break;
      }
    }

    trainersLuchadorCount[trainerOwner]++;
  }

  function removeLuchador(address trainerOwner, uint256 luchadorId) public {
    require(msg.sender == luchador, "Only the luchador contract can remove luchadores");

    uint256 length = trainersLuchadores[trainerOwner].length;
    for (uint256 i = 0; i < length; i++) {
      if (trainersLuchadores[trainerOwner][i] == luchadorId) {
        trainersLuchadores[trainerOwner][i] = 0;
        break;
      }
    }

    trainersLuchadorCount[trainerOwner]--;
  }
}
