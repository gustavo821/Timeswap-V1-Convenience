// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Math} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/Math.sol';
import {FullMath} from './FullMath.sol';

library ConstantProduct {
    using Math for uint256;
    using FullMath for uint256;

    function calculate(
        IPair.State memory state,
        uint256 denominator1,
        uint256 denominator2
    ) internal pure returns (uint256 result) {
        result = (uint256(state.interest) * state.cdp).mulDivUp(state.asset, denominator1 * denominator2);
    }

    function getConstantProduct(
        IPair.State memory state,
        uint256 denominator1,
        uint256 denominator2
    ) internal pure returns (uint256 result) {
        result = ((uint256(state.interest) * state.cdp) << 32).mulDivUp(state.asset, denominator1 * denominator2);
    }
}
