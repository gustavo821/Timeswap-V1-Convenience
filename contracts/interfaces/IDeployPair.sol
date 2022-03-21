// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDeployPair {
    struct DeployPair {
        IERC20 asset;
        IERC20 collateral;
    }
}
