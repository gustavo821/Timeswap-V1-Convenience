// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

import {IERC20} from './IERC20.sol';

/// @title WETH9 Interface
/// @author Ricsson W. Ngo
interface IWETH9 is IERC20 {
    /* ===== UPDATE ===== */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
