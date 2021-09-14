// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Math} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/Math.sol';
import {FullMath} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/FullMath.sol';
import {ConstantProduct} from './ConstantProduct.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library LendMath {
    using Math for uint256;
    using FullMath for uint256;
    using ConstantProduct for IPair;
    using ConstantProduct for ConstantProduct.CP;
    using SafeCast for uint256;

    function givenBond(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint128 bondOut
    ) internal view returns (uint112 yDecrease, uint112 zDecrease) {
        uint256 feeBase = 0x10000 + pair.fee();

        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 _yDecrease = bondOut;
        _yDecrease -= assetIn;
        _yDecrease <<= 32;
        _yDecrease = _yDecrease.divUp(maturity - block.timestamp);
        yDecrease = _yDecrease.toUint112();

        uint256 yAdjust = cp.y;
        yAdjust <<= 16;
        yAdjust -= _yDecrease * feeBase;

        uint256 xAdjust = cp.x;
        xAdjust += assetIn;

        uint256 _zDecrease = xAdjust;
        _zDecrease *= yAdjust;
        uint256 subtrahend = cp.x;
        subtrahend *= cp.y;
        subtrahend <<= 16;
        _zDecrease -= subtrahend;
        uint256 denominator = xAdjust;
        denominator *= yAdjust;
        denominator *= feeBase;
        _zDecrease = _zDecrease.mulDiv(uint256(cp.z) << 16, denominator);
        zDecrease = _zDecrease.toUint112();
    }

    function givenInsurance(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint128 insuranceOut
    ) internal view returns (uint112 yDecrease, uint112 zDecrease) {
        uint256 feeBase = 0x10000 + pair.fee();

        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 _zDecrease = insuranceOut;
        uint256 subtrahend = maturity;
        subtrahend -= block.timestamp;
        subtrahend *= cp.y;
        subtrahend += uint256(cp.x) << 32;
        uint256 denominator = cp.x;
        denominator += assetIn;
        denominator *= uint256(cp.x) << 32;
        subtrahend = subtrahend.mulDivUp(assetIn * cp.z, denominator);
        _zDecrease -= subtrahend;
        zDecrease = _zDecrease.toUint112();

        uint256 zAdjust = cp.z;
        zAdjust <<= 16;
        zAdjust -= zDecrease * feeBase;

        uint256 xAdjust = cp.x;
        xAdjust += assetIn;

        uint256 _yDecrease = xAdjust;
        _yDecrease *= zAdjust;
        subtrahend = cp.x;
        subtrahend *= cp.z;
        subtrahend <<= 16;
        _zDecrease -= subtrahend;
        denominator = xAdjust;
        denominator *= zAdjust;
        denominator *= feeBase;
        _yDecrease = _yDecrease.mulDiv(uint256(cp.y) << 16, denominator);
        yDecrease = _yDecrease.toUint112();
    }

    function givenPercent(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint40 percent
    ) internal view returns (uint112 yDecrease, uint112 zDecrease) {
        uint256 feeBase = 0x10000 + pair.fee();

        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 minimum = assetIn;
        minimum *= cp.y;
        minimum <<= 12;
        uint256 maximum = minimum;
        maximum <<= 4;
        uint256 denominator = cp.x;
        denominator += assetIn;
        denominator *= feeBase;
        minimum /= denominator;
        maximum /= denominator;

        uint256 _yDecrease = maximum;
        _yDecrease -= minimum;
        _yDecrease *= percent;
        _yDecrease >>= 32;
        _yDecrease += minimum;
        yDecrease = _yDecrease.toUint112();

        uint256 yAdjust = cp.y;
        yAdjust <<= 16;
        yAdjust -= _yDecrease * feeBase;

        uint256 xAdjust = cp.x;
        xAdjust += assetIn;

        uint256 _zDecrease = xAdjust;
        _zDecrease *= yAdjust;
        uint256 subtrahend = cp.x;
        subtrahend *= cp.y;
        subtrahend <<= 16;
        _zDecrease -= subtrahend;
        denominator = xAdjust;
        denominator *= yAdjust;
        denominator *= feeBase;
        _zDecrease = _zDecrease.mulDiv(uint256(cp.z) << 16, denominator);
        zDecrease = _zDecrease.toUint112();
    }
}
