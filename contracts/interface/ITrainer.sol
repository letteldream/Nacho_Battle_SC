// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrainer {
    function checkAllowed(address trainerOwner, address luchadorOwner) external view returns (bool);
    function trainersLevel(address trainerOwner) external view returns (uint256);
    function isLuchadorInTrainer(uint256 luchadorId, address trainerOwner) external view returns (bool);
    function placeLuchador(address trainerOwner, uint256 luchadorId) external;
    function removeLuchador(address trainerOwner, uint256 luchadorId) external;
}