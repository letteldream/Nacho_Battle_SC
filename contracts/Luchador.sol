// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/ITrainer.sol";

contract Luchador is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
  uint256 public constant ATTRIBUTE_COUNT = 20;
  uint256 public constant IDLE = ATTRIBUTE_COUNT + 1;

  uint256 public luchadorWeightModifier = 100 ether;
  uint256 public luchadorBaseWeight = 100 ether;

  ERC20Burnable public nacho;
  // ERC20Burnable(0xcD86152047e800d67BDf00A4c635A8B6C0e5C4c2);
  ERC20Burnable public nbond;
  // ERC20Burnable(0xfc4a30f328E946ef3E727BD294a93e84c2e43c24);
  IERC20 public eth;
  //  = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

  uint256 public whitelistStart = 1654002000;
  uint256 public openMarketStart = 1654174800;

  uint256 public whitelistPrice = 0.02 ether;
  uint256 public openMarketPrice = 0.04 ether;

  uint256 public maxTotalSupply = 3300;

  uint256 public nameEditCost = 1 ether;
  uint256 public bioEditCost = 1 ether;

  address public multisig;
  // address(0x5FFCc9f5d9ee5E057878F7A4D0DB8cb6d0598b50);
  address[ATTRIBUTE_COUNT] public trainers;

  uint256 public multisigMaxMintCount = 667;

  address public fightingContract;

  struct LuchadorData {
    string tokenURI;
    uint256[ATTRIBUTE_COUNT] attributes;
    uint256 location;
    address currentTrainerOwner;
    uint256 locationStartTime;
    uint256 weight;
    uint256 wins;
    uint256 losses;
    string name;
    string bio;
    uint256 price;
    uint256 index;
    uint256 lastSalePrice;
    bool saleStatus;
  }

  mapping(uint256 => uint256[ATTRIBUTE_COUNT]) public luchadoresAttributes;
  mapping(uint256 => uint256) public luchadoresLocation;
  mapping(uint256 => address) public luchadoresCurrentTrainerOwner;
  mapping(uint256 => uint256) public luchadoresLocationStartTime;
  mapping(uint256 => uint256) public luchadoresWeight;
  mapping(uint256 => uint256) public luchadoresWins;
  mapping(uint256 => uint256) public luchadoresLosses;
  mapping(uint256 => string) public luchadoresName;
  mapping(uint256 => string) public luchadoresBio;

  uint256[] public luchadoresForSale;
  mapping(uint256 => uint256) public luchadoresPrice;
  mapping(uint256 => uint256) public luchadoresIndex;
  mapping(uint256 => uint256) public luchadoresLastSalePrice;
  mapping(uint256 => bool) public luchadoresSaleStatus;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  string[] private unmintedTokenURIs;

  constructor(
    address _nacho,
    address _nbond,
    address _weth,
    address _multisig
  ) ERC721("Luchador", "LUC") {
    nacho = ERC20Burnable(_nacho);
    nbond = ERC20Burnable(_nbond);
    eth = IERC20(_weth);
    multisig = _multisig;
  }

  function _mintLuchador(string memory _tokenURI) internal {
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, _tokenURI);

    luchadoresLocation[tokenId] = IDLE;
    luchadoresName[tokenId] = "Luchador";
    luchadoresBio[tokenId] = "Luchador NFT by Nacho Finance";
    luchadoresSaleStatus[tokenId] = false;
  }

  function mint(uint256 amount) external {
    require(amount > 0, "Minimum 1 NFT to mint");
    require((totalSupply() + amount) <= maxTotalSupply, "Not enough NFTs left to be minted");
    require(amount <= unmintedTokenURIs.length, "Not enough unminted token URIs");

    if (block.timestamp >= openMarketStart) {
      eth.transferFrom(msg.sender, multisig, openMarketPrice * amount);
    } else if (block.timestamp >= whitelistStart) {
      eth.transferFrom(msg.sender, multisig, whitelistPrice * amount);
    } else {
      require(false, "Minting hasn't started yet");
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 selectedTokenURIIndex = uint256(keccak256(abi.encodePacked(block.timestamp + i))) % unmintedTokenURIs.length;

      string memory selectedTokenURI = unmintedTokenURIs[selectedTokenURIIndex];

      //We can't avoid executing those transactions for the last item so gas estimates are reliable
      string memory lastUnmintedTokenURI = unmintedTokenURIs[unmintedTokenURIs.length - 1];
      unmintedTokenURIs[selectedTokenURIIndex] = lastUnmintedTokenURI;

      unmintedTokenURIs.pop();

      _mintLuchador(selectedTokenURI);
    }
  }

  function specialMint(string memory _tokenURI) external onlyOwner {
    maxTotalSupply += 1;
    _mintLuchador(_tokenURI);
  }

  function multisigMint(uint256 amount) external onlyOwner {
    require(amount <= multisigMaxMintCount, "Amount greater than remaining mint count");
    require(unmintedTokenURIs.length >= amount, "Not enough unminted token URIs to fulfil multisig allocation");

    multisigMaxMintCount -= amount;

    for (uint256 i = 0; i < amount; i++) {
      uint256 selectedTokenURIIndex = uint256(keccak256(abi.encodePacked(block.timestamp + i))) % unmintedTokenURIs.length;

      string memory selectedTokenURI = unmintedTokenURIs[selectedTokenURIIndex];

      string memory lastUnmintedTokenURI = unmintedTokenURIs[unmintedTokenURIs.length - 1];
      unmintedTokenURIs[selectedTokenURIIndex] = lastUnmintedTokenURI;

      unmintedTokenURIs.pop();

      _mintLuchador(selectedTokenURI);
    }
  }

  function setWhitelistStart(uint256 change) external onlyOwner {
    whitelistStart = change;
  }

  function setWhitelistPrice(uint256 change) external onlyOwner {
    whitelistPrice = change;
  }

  function setOpenMarketStart(uint256 change) external onlyOwner {
    openMarketStart = change;
  }

  function setOpenMarketPrice(uint256 change) external onlyOwner {
    openMarketPrice = change;
  }

  function setNameEditCost(uint256 change) external onlyOwner {
    nameEditCost = change;
  }

  function setBioEditCost(uint256 change) external onlyOwner {
    bioEditCost = change;
  }

  function setMaxTotalSupply(uint256 change) external onlyOwner {
    maxTotalSupply = change;
  }

  function setTrainer(uint256 trainer, address trainerAddress) external onlyOwner {
    trainers[trainer] = trainerAddress;
  }

  function setLuchadorWeightModifier(uint256 change) external onlyOwner {
    luchadorWeightModifier = change;
  }

  function setLuchadorBaseWeight(uint256 change) external onlyOwner {
    luchadorBaseWeight = change;
  }

  function addTokenURI(string memory newTokenURI) external onlyOwner {
    unmintedTokenURIs.push(newTokenURI);
  }

  function setFightingContract(address _fightingContract) external onlyOwner {
    fightingContract = _fightingContract;
  }

  function addLuchadorWin(uint256 luchadorId) external {
    require(msg.sender == fightingContract, "Only the fighting contract can call this");
    luchadoresWins[luchadorId]++;
  }

  function addLuchadorLoss(uint256 luchadorId) external {
    require(msg.sender == fightingContract, "Only the fighting contract can call this");
    luchadoresLosses[luchadorId]++;
  }

  //Very dangerous race condition, but string comparisons would be extremely expensive, use this with caution
  function removeTokenURI(uint256 index) external onlyOwner {
    string memory lastUnmintedTokenURI = unmintedTokenURIs[unmintedTokenURIs.length - 1];
    unmintedTokenURIs[index] = lastUnmintedTokenURI;

    unmintedTokenURIs.pop();
  }

  function doesOwnLuchador(address owner, uint256 luchadorId) public view returns (bool) {
    return _exists(luchadorId) && ownerOf(luchadorId) == owner;
  }

  function setLuchadorName(uint256 luchadorId, string memory _luchadorName) external {
    require(doesOwnLuchador(msg.sender, luchadorId), "Luchador doesn't exist yet or sender not luchador owner");

    if (nameEditCost > 0) {
      nacho.transferFrom(msg.sender, address(this), nameEditCost);
      nacho.burn(nameEditCost);
    }

    luchadoresName[luchadorId] = _luchadorName;
  }

  function setLuchadorBio(uint256 luchadorId, string memory _luchadorBio) external {
    require(doesOwnLuchador(msg.sender, luchadorId), "Luchador doesn't exist yet or sender not luchador owner");

    if (bioEditCost > 0) {
      nacho.transferFrom(msg.sender, address(this), bioEditCost);
      nacho.burn(bioEditCost);
    }

    luchadoresBio[luchadorId] = _luchadorBio;
  }

  function getAllTrainers() public view returns (address[ATTRIBUTE_COUNT] memory) {
    return trainers;
  }

  function getAllLuchadorAttributes(uint256 luchadorId) public view returns (uint256[ATTRIBUTE_COUNT] memory) {
    return luchadoresAttributes[luchadorId];
  }

  function getAllLuchadoresForSale() public view returns (uint256[] memory) {
    return luchadoresForSale;
  }

  function isLuchadorForSale(uint256 luchadorId) public view returns (bool) {
    return luchadoresSaleStatus[luchadorId];
  }

  function getLuchadoresData() public view returns (LuchadorData[] memory) {
    uint256 _totalSupply = totalSupply();
    LuchadorData[] memory luchadores = new LuchadorData[](_totalSupply);

    for (uint256 i = 1; i < _totalSupply + 1; i++) {
      luchadores[i - 1].tokenURI = super.tokenURI(i);
      luchadores[i - 1].attributes = luchadoresAttributes[i];
      luchadores[i - 1].location = luchadoresLocation[i];
      luchadores[i - 1].currentTrainerOwner = luchadoresCurrentTrainerOwner[i];
      luchadores[i - 1].locationStartTime = luchadoresLocationStartTime[i];
      luchadores[i - 1].weight = luchadoresWeight[i];
      luchadores[i - 1].wins = luchadoresWins[i];
      luchadores[i - 1].losses = luchadoresLosses[i];
      luchadores[i - 1].name = luchadoresName[i];
      luchadores[i - 1].bio = luchadoresBio[i];
      luchadores[i - 1].price = luchadoresPrice[i];
      luchadores[i - 1].index = luchadoresIndex[i];
      luchadores[i - 1].lastSalePrice = luchadoresLastSalePrice[i];
      luchadores[i - 1].saleStatus = luchadoresSaleStatus[i];
    }

    return luchadores;
  }

  function setForSale(uint256 luchadorId, uint256 price) external {
    require(doesOwnLuchador(msg.sender, luchadorId), "Luchador doesn't exist yet or sender not luchador owner");
    require(!isLuchadorForSale(luchadorId), "Luchador already on sale");

    luchadoresSaleStatus[luchadorId] = true;

    if (luchadoresLocation[luchadorId] != IDLE) removeFromTrainer(luchadorId);

    luchadoresForSale.push(luchadorId);
    luchadoresIndex[luchadorId] = luchadoresForSale.length - 1;
    luchadoresPrice[luchadorId] = price;
  }

  function _deleteSale(uint256 luchadorId) internal {
    luchadoresSaleStatus[luchadorId] = false;

    uint256 saleIndex = luchadoresIndex[luchadorId];

    uint256 lastLuchadorForSaleId = luchadoresForSale[luchadoresForSale.length - 1];
    luchadoresForSale[saleIndex] = lastLuchadorForSaleId;
    luchadoresIndex[lastLuchadorForSaleId] = saleIndex;

    luchadoresForSale.pop();

    delete luchadoresPrice[luchadorId];
  }

  function removeFromSale(uint256 luchadorId) external {
    require(doesOwnLuchador(msg.sender, luchadorId), "Luchador doesn't exist yet or sender not luchador owner");
    require(isLuchadorForSale(luchadorId), "Sale not found");

    _deleteSale(luchadorId);
  }

  function buyLuchador(uint256 luchadorId, uint256 expectedPrice) external {
    require(_exists(luchadorId), "Luchador doesn't exist yet");

    address tokenOwner = ownerOf(luchadorId);
    require(msg.sender != tokenOwner, "Buyer is already the luchador owner");

    uint256 price = luchadoresPrice[luchadorId];
    require(price == expectedPrice, "Expected and actual price didn't match");

    require(isLuchadorForSale(luchadorId), "Sale not found");

    uint256 royaltiesAmount = price / 10;
    uint256 payOwnerAmount = price - royaltiesAmount;

    eth.transferFrom(msg.sender, multisig, royaltiesAmount);
    eth.transferFrom(msg.sender, tokenOwner, payOwnerAmount);

    luchadoresLastSalePrice[luchadorId] = price;

    //sale is deleted on the before transfer hook
    _transfer(tokenOwner, msg.sender, luchadorId);
  }

  function feedNacho(uint256 luchadorId, uint256 amount) external {
    nacho.transferFrom(msg.sender, address(this), amount);
    nacho.burn(amount);

    if (block.timestamp < openMarketStart) amount *= 3;
    else if (block.timestamp < (openMarketStart + 14 days)) amount *= 2;

    luchadoresWeight[luchadorId] += amount;
  }

  function feedNbond(uint256 luchadorId, uint256 amount) external {
    nbond.transferFrom(msg.sender, address(this), amount);
    nbond.burn(amount);

    if (block.timestamp < openMarketStart) amount *= 6;
    else if (block.timestamp < (openMarketStart + 14 days)) amount *= 5;
    else amount *= 4;

    luchadoresWeight[luchadorId] += amount;
  }

  function sendToTrainer(
    uint256 luchadorId,
    address trainerOwner,
    uint256 trainer
  ) external {
    require(doesOwnLuchador(msg.sender, luchadorId), "Luchador doesn't exist yet or sender not luchador owner");
    require(ITrainer(trainers[trainer]).checkAllowed(trainerOwner, msg.sender), "Sender not allowed on trainer");
    require(luchadoresLocation[luchadorId] == IDLE, "Luchador not idle");

    ITrainer(trainers[trainer]).placeLuchador(trainerOwner, luchadorId);

    luchadoresLocation[luchadorId] = trainer;
    luchadoresCurrentTrainerOwner[luchadorId] = trainerOwner;
    luchadoresLocationStartTime[luchadorId] = block.timestamp;
  }

  function canRemoveLuchadorFromTrainer(uint256 luchadorId, uint256 currentTrainer) public view returns (bool) {
    //Luchador exists
    if (!_exists(luchadorId)) return false;

    //sender is the owner
    if (msg.sender == ownerOf(luchadorId)) return true;

    //sender is a trainer contract
    if (msg.sender == trainers[currentTrainer]) return true;

    //Luchador is in sender's trainer
    return ITrainer(trainers[currentTrainer]).isLuchadorInTrainer(luchadorId, msg.sender);
  }

  function removeFromTrainer(uint256 luchadorId) public {
    uint256 currentTrainer = luchadoresLocation[luchadorId];

    require(currentTrainer != IDLE, "Luchador already idle");
    require(canRemoveLuchadorFromTrainer(luchadorId, currentTrainer), "Sender not allowed to remove luchador");

    address trainerOwner = luchadoresCurrentTrainerOwner[luchadorId];
    ITrainer(trainers[currentTrainer]).removeLuchador(trainerOwner, luchadorId);

    uint256 elapsedSeconds = block.timestamp - luchadoresLocationStartTime[luchadorId];
    uint256 pointsEarned = elapsedSeconds * ((luchadorBaseWeight + luchadoresWeight[luchadorId]) / luchadorWeightModifier);

    pointsEarned *= ITrainer(trainers[currentTrainer]).trainersLevel(trainerOwner)**2;

    luchadoresAttributes[luchadorId][currentTrainer] += pointsEarned;

    luchadoresLocation[luchadorId] = IDLE;
    luchadoresCurrentTrainerOwner[luchadorId] = address(0);
    luchadoresLocationStartTime[luchadorId] = 0;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);

    if (_exists(tokenId) && luchadoresLocation[tokenId] != IDLE) removeFromTrainer(tokenId);

    if (_exists(tokenId) && isLuchadorForSale(tokenId)) _deleteSale(tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
