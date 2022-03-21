// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IClaim} from './interfaces/IClaim.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract InsurancePrincipal is IClaim, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Insurance Principal- ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-INS-PRI-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function decimals() external view override returns (uint8) {
        return pair.collateral().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.claimsOf(maturity, address(convenience)).insurancePrincipal;
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Insurance Principal') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint128 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint128 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}
