// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

import {InterfaceTimeswapETHAsset} from "./interfaces/InterfaceTimeswapETHAsset.sol";
import {InterfaceTimeswapFactory} from "./interfaces/InterfaceTimeswapFactory.sol";
import {InterfaceTimeswapPool} from "./interfaces/InterfaceTimeswapPool.sol";
import {InterfaceWETH9} from "./interfaces/InterfaceWETH9.sol";
import {InterfaceERC20} from "./interfaces/InterfaceERC20.sol";
import {InterfaceTimeswapERC721} from "./interfaces/InterfaceTimeswapERC721.sol";
import {TimeswapCalculate} from "./libraries/TimeswapCalculate.sol";


/// @title Timeswap Convenience ETH Asset
/// @author Ricsson W. Ngo
/// @dev Conveniently call the core functions in Timeswap Core contract
/// @dev The asset parameter for all transaction is the WETH ERC20 for transactions with ETH
/// @dev Precalculate and transfer necessary tokens to the Timeswap Core contract
/// @dev Does safety checks in regards to slippage and deadline
contract TimeswapETHAsset is InterfaceTimeswapETHAsset {
    using TimeswapCalculate for InterfaceTimeswapPool;

    /* ===== MODEL ===== */

    bytes4 private constant TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFER_FROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    InterfaceTimeswapPool private constant ZERO = InterfaceTimeswapPool(address(type(uint160).min));

    /// @dev The address of the Timeswap Core factory contract that deploys Timeswap pools
    InterfaceTimeswapFactory public immutable override factory;
    /// @dev The address of the WETH ERC20 contract that wraps ETH to follow the ERC20 standard
    InterfaceWETH9 public immutable override weth;

    /// @dev Set deadlines for when the transactions are not executed fast enough
    modifier ensure(uint256 _deadline) {
        require(_deadline >= block.timestamp, "TimeswapETHAsset : ensure : Expired");
        _;
    }

    /* ===== INIT ===== */

    /// @dev First deploy the Timeswap Core factory contract
    /// @dev Then deploy or use the WETH ERC20 contract
    /// @dev Finally deploy the Timeswap Convenience contract
    /// @param _factory The address of the Timeswap Core factory contract
    /// @param _weth The address of the WETH ERC20 contract
    constructor(InterfaceTimeswapFactory _factory, InterfaceWETH9 _weth) {
        factory = _factory;
        weth = _weth;
    }

    /* ===== UPDATE ===== */

    /// @dev Deploy a new Timeswap pool contract and initialize the liquidity with the first mint function in the Timeswap Core contract
    /// @dev The msg.value determines _insuranceReceivedAndAssetIn which is the amount of insurance ERC20 received by the receiver and the increase in the X pool
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the mint function
    /// @param _bondIncreaseAndCollateralPaid The increase in the Y pool and the amount of collateral ERC20 to be deposited to the pool contract
    /// @param _bondReceivedAndCollateralLocked The amount of bond ERC20 received by the receiver and the amount of collateral ERC20 to be locked
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _tokenId The id of the newly minted collateralized debt ERC721 token contract
    /// @return _insuranceIncreaseAndDebtRequired The increase in the V pool and the amount of debt received
    /// @return _liquidityReceived The amount of liquidity ERC20 received
    function mint(
        Parameter memory _parameter,
        address _to,
        uint256 _bondIncreaseAndCollateralPaid,
        uint256 _bondReceivedAndCollateralLocked,
        uint256 _deadline
    )
        external
        override
        payable
        ensure(_deadline)
        returns (
            uint256 _tokenId,
            uint256 _insuranceIncreaseAndDebtRequired,
            uint256 _liquidityReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);

        // Deploy a new Timeswap pool if the pool does not exist
        if (_pool == ZERO) _pool = _createPool(_parameter);

        // Check if pool have liquidity
        require(_pool.totalSupply() == 0, "TimeswapETHAsset :: mint : Pool already have Liquidity");

        // Calculate one of the parameter for the mint function in the Timeswap Core contract
        _insuranceIncreaseAndDebtRequired = msg.value * _bondReceivedAndCollateralLocked / _bondIncreaseAndCollateralPaid;

        // Safely transfer and wrap the necessary tokens to the Timeswap Core pool
        _wethDepositTransfer(_pool, msg.value);
        _safeTransferFrom(_parameter.collateral, msg.sender, address(_pool),  _bondIncreaseAndCollateralPaid + _bondReceivedAndCollateralLocked);

        // Call the mint function in the Timeswap Core
        (_tokenId,,, _liquidityReceived) = _pool.mint(
            _to,
            _bondIncreaseAndCollateralPaid,
            _insuranceIncreaseAndDebtRequired
        );
    }

    /// @dev Add more liquidity into an existing Timeswap pool with the mint function in the Timeswap Core contract
    /// @dev The msg.value determines _insuranceReceivedAndAssetIn which is the amount of insurance ERC20 received by the receiver and the increase in the X pool
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the mint function
    /// @param _safe The slippage protections of the mint transaction
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _tokenId The id of the newly minted collateralized debt ERC721 token contract
    /// @return _bondIncreaseAndCollateralPaid The increase in the Y pool and the amount of collateral ERC20 to be deposited to the pool contract
    /// @return _insuranceIncreaseAndDebtRequired The increase in the V pool and the amount of debt received
    /// @return _bondReceivedAndCollateralLocked The amount of bond ERC20 received by the receiver and the amount of collateral ERC20 to be locked
    /// @return _liquidityReceived The amount of liquidity ERC20 received
    function mint(
        Parameter memory _parameter,
        address _to,
        SafeMint memory _safe,
        uint256 _deadline
    )
        external
        override
        payable
        ensure(_deadline)
        returns (
            uint256 _tokenId,
            uint256 _bondIncreaseAndCollateralPaid,
            uint256 _insuranceIncreaseAndDebtRequired,
            uint256 _bondReceivedAndCollateralLocked,
            uint256 _liquidityReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: mint : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: mint : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: mint : No Liquidity");

        // Calculate the necessary parameters for the mint function in the Timeswap Core contract
        (_bondIncreaseAndCollateralPaid, _insuranceIncreaseAndDebtRequired, _bondReceivedAndCollateralLocked) = _pool.calculateMint(msg.value);

        // Safely transfer and wrap the necessary tokens to the Timeswap Core pool
        _wethDepositTransfer(_pool, msg.value);
        _safeTransferFrom(_parameter.collateral, msg.sender, address(_pool), _bondIncreaseAndCollateralPaid + _bondReceivedAndCollateralLocked);

        // Call the mint function in the Timeswap Core
        (_tokenId, _bondReceivedAndCollateralLocked,, _liquidityReceived) = _pool.mint(
            _to,
            _bondIncreaseAndCollateralPaid,
            _insuranceIncreaseAndDebtRequired
        );

        // Check slippage protection
        require(_insuranceIncreaseAndDebtRequired <= _safe.maxDebt, "TimeswapETHAsset :: mint : Over the maxDebt");
        require(_bondIncreaseAndCollateralPaid <= _safe.maxCollateralPaid, "TimeswapETHAsset :: mint : Over the maxCollateralPaid");
        require(_bondReceivedAndCollateralLocked <= _safe.maxCollateralLocked, "TimeswapETHAsset :: mint : Over the maxCollateralLocked");
    }

    /// @dev Withdraw liquidity from a Timeswap pool before maturity with the burn function in the Timeswap Core contract
    /// @dev Precalculate the collateral ERC20 to be locked
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the burn function
    /// @param _liquidityIn The amount of liquidity ERC20 to be burnt
    /// @param _maxCollateralLocked The maximum amount of collateral ERC20 willing to be locked
    /// @param _safe The slippage protections of the burn transaction
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _tokenId The id of the newly minted collateralized debt ERC721 token contract, returns zero if no Collateralized Debt ERC721 is minted
    /// @return _collateralLocked The actual collateral ERC20 locked in the Timeswap Core
    /// @return _debtRequiredAndAssetReceived The debt required and the asset ERC20 received by the receiver
    /// @return _bondReceived The amount of bond ERC20 received by the receiver
    /// @return _insuranceReceived The amount of insurance ERC20 received by the receiver
    function burn(
        Parameter memory _parameter,
        address payable _to,
        uint256 _liquidityIn,
        uint256 _maxCollateralLocked,
        SafeBurn memory _safe,
        uint256 _deadline
    )
        external
        override
        ensure(_deadline)
        returns (
            uint256 _tokenId,
            uint256 _collateralLocked,
            uint256 _debtRequiredAndAssetReceived,
            uint256 _bondReceived,
            uint256 _insuranceReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: burn : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: burn : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: burn : No Liquidity");

        // Safely transfer liquidity ERC20 to the Timeswap Core pool
        _safeTransferFrom(_pool, msg.sender, address(_pool), _liquidityIn);

        if (_maxCollateralLocked > 0) {
            // Calculate the collateral ERC20 required to lock
            _collateralLocked = _pool.calculateBurn(_liquidityIn, _maxCollateralLocked);

            // Safely transfer collateral ERC20 to the Timeswap Core pool
            _safeTransferFrom(_parameter.collateral, msg.sender, address(_pool), _collateralLocked);
        }

        // Call the burn function in the Timeswap Core
        (_tokenId, _collateralLocked, _debtRequiredAndAssetReceived, _bondReceived, _insuranceReceived) = _pool.burn(_to);

        // Unwrap the WETH and safely transfer ETH to the receiver
        if (_debtRequiredAndAssetReceived > 0) _wethWithdrawTransfer(_to, _debtRequiredAndAssetReceived);

        // Check slippage protection
        require(_debtRequiredAndAssetReceived >= _safe.minAsset, "TimeswapETHAsset :: burn : Under the minAsset");
        require(_bondReceived >= _safe.minBond, "TimeswapETHAsset :: burn : Under the minBond");
        require(_insuranceReceived >= _safe.minInsurance, "TimeswapETHAsset :: burn : Under the minInsurance");
    }

    /// @dev Withdraw liquidity from a Timeswap pool after maturity with the burn function in the Timeswap Core contract
    /// @dev No need for deadline and slippage protection as no slippage can happen after maturity of the pool
    /// @dev No Collateralized Debt ERC721 will be minted anymore after maturity of the pool
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the burn function
    /// @param _liquidityIn The amount of liquidity ERC20 to be burnt
    /// @return _bondReceived The amount of bond ERC20 received by the receiver
    /// @return _insuranceReceived The amount of insurance ERC20 received by the receiver
    function burn(
        Parameter memory _parameter,
        address _to,
        uint256 _liquidityIn
    )
        external
        override
        returns (
            uint256 _bondReceived,
            uint256 _insuranceReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: burn : Pool Does Not Exist");
        require(_pool.maturity() <= block.timestamp, "TimeswapETHAsset :: burn : Pool Not Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: burn : No Liquidity");
        
        // Safely transfer liquidity ERC20 to the Timeswap Core pool
        _safeTransferFrom(_pool, msg.sender, address(_pool), _liquidityIn);

        // Call the burn function in the Timeswap Core
        (,,, _bondReceived, _insuranceReceived) = _pool.burn(_to);
    }

    /// @dev Lend asset ERC20 with the lend function in the Timeswap Core contract
    /// @dev The msg.value determines _assetIn which is the amount of asset ERC20 to be lent
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the lend function
    /// @param _isBondReceivedGiven Determines whether the lender provides desired bond receive, if false assume lender provide desired insurance receive
    /// @param _bondReceivedOrInsuranceReceived The desired amount of bond ERC20 received or the desired amount of insurance ERC20 received
    /// @param _safe The slippage protections of the lend transaction
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _bondReceived The actual amount of bond ERC20 received by the receiver
    /// @return _insuranceReceived The actual amount of insurance ERC20 received by the receiver
    function lend(
        Parameter memory _parameter,
        address _to,
        bool _isBondReceivedGiven,
        uint256 _bondReceivedOrInsuranceReceived,
        SafeLend memory _safe,
        uint256 _deadline
    )
        external
        override
        payable
        ensure(_deadline)
        returns (
            uint256 _bondReceived,
            uint256 _insuranceReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: lendWithBond : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: lendWithBond : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: lendWithBond : No Liquidity");
        
        // Calculate the necessary parameters for the lend function in the Timeswap Core contract
        uint256 _bondDecrease;
        uint256 _rateDecrease;
        if (_isBondReceivedGiven) {
            (_bondDecrease, _rateDecrease) = _pool.calculateLendGivenBondReceived(
                msg.value,
                _bondReceivedOrInsuranceReceived
            );
        }
        else {
            (_bondDecrease, _rateDecrease) = _pool.calculateLendGivenInsuranceReceived(
                msg.value,
                _bondReceivedOrInsuranceReceived
            );
        }

        // Safely wrap and transfer ETH to the Timeswap Core pool
        _wethDepositTransfer(_pool, msg.value);

        // Call the lend function in the Timeswap Core
        (_bondReceived, _insuranceReceived) = _pool.lend(_to, _bondDecrease, _rateDecrease);

        // Check slippage protection
        require(_bondReceived >= _safe.minBond, "TimeswapETHAsset :: lend : Under the minBond");
        require(_insuranceReceived >= _safe.minInsurance, "TimeswapETHAsset :: lend : Under the minInsurance");
    }

    /// @dev Borrw asset ERC20 and lock collateral with the borrow function in the Timeswap Core contract
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _to The receiver of the borrow function
    /// @param _assetReceived The amount of asset ERC20 to be borrowed
    /// @param _isDesiredCollateralLockedGiven Determines whether the borrower provides desired collateral lock, if false assume lender provide desired interest required
    /// @param _desiredCollateralLockedOrInterestRequired The desired amount of collateral ERC20 lock or the desired amount of interest required
    /// @param _safe The slippage protections of the borrow transaction
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _tokenId The id of the newly minted collateralized debt ERC721 token contract
    /// @return _collateralLocked The actual amount of collateral ERC20 locked by the receiver
    /// @return _debtRequired The actual amount of debt required
    function borrow(
        Parameter memory _parameter,
        address payable _to,
        uint256 _assetReceived,
        bool _isDesiredCollateralLockedGiven,
        uint256 _desiredCollateralLockedOrInterestRequired,
        SafeBorrow memory _safe,
        uint256 _deadline
    )
        external
        override
        ensure(_deadline)
        returns (
            uint256 _tokenId,
            uint256 _collateralLocked,
            uint256 _debtRequired
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: borrowWithCollateral : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: borrowWithCollateral : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: borrowWithCollateral : No Liquidity");

        // Calculate the necessary parameters for the borrow function in the Timeswap Core contract
        uint256 _bondIncrease;
        uint256 _rateIncrease;
        if (_isDesiredCollateralLockedGiven) {
            (_bondIncrease, _rateIncrease, _collateralLocked) = _pool.calculateBorrowGivenDesiredCollateralLocked(
                _assetReceived,
                _desiredCollateralLockedOrInterestRequired
            );
        }
        else {
            (_bondIncrease, _rateIncrease, _collateralLocked) = _pool.calculateBorrowGivenInterestRequired(
                _assetReceived,
                _desiredCollateralLockedOrInterestRequired
            );
        }

        // Safely transfer collateral ERC20 to the Timeswap Core pool
        _safeTransferFrom(_parameter.collateral, msg.sender, address(_pool), _collateralLocked);

        // Call the borrow function in the Timeswap Core to this address
        (_tokenId, _collateralLocked, _debtRequired) = _pool.borrow(_to, _assetReceived, _bondIncrease, _rateIncrease);

        // Unwrap the WETH and safely transfer ETH to the receiver
        _wethWithdrawTransfer(_to, _assetReceived);

        // Check slippage protection
        require(_collateralLocked <= _safe.maxCollateralLocked, "TimeswapETHAsset :: borrow : Over the maxCollateralLocked");
        require(_debtRequired - _assetReceived <= _safe.maxInterestRequired, "TimeswapETHAsset :: borrow : Over the maxInterestRequired");
    }

    /// @dev Pay back the debt of the collateralized debt ERC721 with the pay function in the Tiemswap Core contract
    /// @dev No need for slippage protection as no slippage can happen with debt payment
    /// @dev The msg.value determines the _assetIn which is the amount of asset ERC20 to be deposited to pay back debt
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _tokenId The id of the collateralized debt ERC721, the receiver is the owner of the token
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _collateralReceived The amount of collateral ERC20 to be unlocked and received by the receiver
    function pay(
        Parameter memory _parameter,
        uint256 _tokenId,
        uint256 _deadline
    )
        external
        override
        payable
        ensure(_deadline)
        returns (
            uint256 _collateralReceived
        )
    {
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: pay : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: pay : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: pay : No Liquidity");

        // Safely wrap and transfer ETH to the Timeswap Core pool
        _wethDepositTransfer(_pool, msg.value);
        
        // Call the pay function in the Timeswap Core
        _collateralReceived = _pool.pay(_tokenId);
    }

    /// @dev Pay back the debt of multiple collateralized debt ERC721 with the multiple pay function in the Tiemswap Core contract
    /// @dev No need for slippage protection as no slippage can happen with debt payment
    /// @dev The msg.value must be greater than or equal to the sum of the _assetsIn array
    /// @param _parameter The three parameters for the Timeswap pool
    /// @param _tokenIds The array of ids of the collateralized debt ERC721, the receiver is the owner of the token
    /// @param _assetsIn The array of amount of asset ERC20 to be deposited to pay back debt per collateralized debt ERC721
    /// @param _deadline The unix timestamp where the transactions must revert after
    /// @return _collateralReceived The total amount of collateral ERC20 to be unlocked
    function pay(
        Parameter memory _parameter,
        uint256[] memory _tokenIds,
        uint256[] memory _assetsIn,
        uint256 _deadline
    )
        external
        override
        payable
        ensure(_deadline)
        returns (
            uint256 _collateralReceived
        )
    {
        // Must have equal lengths array
        require(_tokenIds.length == _assetsIn.length, "TimeswapETHAsset :: pay : Unequal Length");
        
        // Get the address of the pool
        InterfaceTimeswapPool _pool = _getPool(_parameter);
        // Sanity checks
        require(_pool != ZERO, "TimeswapETHAsset :: pay : Pool Does Not Exist");
        require(_pool.maturity() > block.timestamp, "TimeswapETHAsset :: pay : Pool Matured");
        require(_pool.totalSupply() > 0, "TimeswapETHAsset :: pay : No Liquidity");

        for (uint256 _index = 0; _index < _tokenIds.length; _index++) {
            // Safely wrap and transfer ETH to the Timeswap Core pool
            _wethDepositTransfer(_pool, _assetsIn[_index]);

            // Call the pay function in the Timeswap Core
            _collateralReceived += _pool.pay(_tokenIds[_index]);
        }

        // Return any ETH back
        uint256 _ethOut = address(this).balance;
        if (_ethOut > 0) {
            (bool _success, bytes memory _data) = payable(msg.sender).call{value: _ethOut}("");
            require(_success && (_data.length == 0 || abi.decode(_data, (bool))), "TimeswapETHAsset :: pay : ETH Transfer Failed");
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* ===== HELPER ===== */

    /// @dev Safely transfer the tokens of an ERC20 token contract
    /// @dev Will revert if failed at calling the transfer function
    function _safeTransferFrom(InterfaceERC20 _token, address _from, address _to, uint256 _value) private {
        (bool _success, bytes memory _data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM, _from, _to, _value));
        require(_success && (_data.length == 0 || abi.decode(_data, (bool))), "TimeswapETHAsset :: _safeTransferFrom : Transfer Failed");
    }

    /// @dev Safely wrap and transfer ETH to the Timeswap Core pool
    /// @dev Will revert if failed at calling the transfer function
    function _wethDepositTransfer(InterfaceTimeswapPool _pool, uint256 _value) private {
        InterfaceWETH9 _weth = weth; // gas savings

        // Wrap ETH
        _weth.deposit{value: _value}();

        // Transfer WETH to Timeswap Core pool
        (bool _success, bytes memory _data) = address(_weth).call(abi.encodeWithSelector(TRANSFER, address(_pool), _value));
        require(_success && (_data.length == 0 || abi.decode(_data, (bool))), "TimeswapETHAsset :: _wethDepositTransfer : Transfer Failed");

        // Return any ETH back
        uint256 _ethOut = address(this).balance;
        if (_ethOut > 0) {
            (_success, _data) = payable(msg.sender).call{value: _ethOut}("");
            require(_success && (_data.length == 0 || abi.decode(_data, (bool))), "TimeswapETHAsset :: pay : ETH Transfer Failed");
        }
    }

    /// @dev Safely unwrap and transfer ETH
    /// @dev Required WETH contract approve from the receiver
    /// @dev Will revert if failed at calling the transfer function
    function _wethWithdrawTransfer(address payable _to, uint256 _value) private {
        InterfaceWETH9 _weth = weth; // gas savings

        // Safely transfer WETH to the this address
        _safeTransferFrom(_weth, _to, address(this), _value);

        // Unwrap WETH and transfer ETH to the receiver
        uint256 _ethOut = _weth.balanceOf(address(this));
        _weth.withdraw(_ethOut);
        (bool _success, bytes memory _data) = _to.call{value: _ethOut}("");
        require(_success && (_data.length == 0 || abi.decode(_data, (bool))), "TimeswapETHAsset :: _wethWithdrawTransfer : ETH Transfer Failed");
    }

    /// @dev Get the address of the Timeswap Core pool given the parameters
    function _getPool(Parameter memory _parameter) private view returns (InterfaceTimeswapPool _pool) {
        _pool = factory.getPool(weth, _parameter.collateral, _parameter.maturity);
    }

    /// @dev Deploy a new Timeswap Core pool given the parameters
    function _createPool(Parameter memory _parameter) private returns (InterfaceTimeswapPool _pool) {
        _pool = factory.createPool(weth, _parameter.collateral, _parameter.maturity);
    }
}
