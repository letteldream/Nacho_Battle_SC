// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract VRFCoordinatorMock is VRFCoordinatorV2Mock {
  constructor() VRFCoordinatorV2Mock(0, 0) {}
}
