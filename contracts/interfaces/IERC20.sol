// SPDX-License-Identifier: MIT
pragma solidity =0.8.1;

/// @title ERC20 Interface
/// @author Ricsson W. Ngo
interface IERC20 {
    // EVENT

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // VIEW

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    // UPDATE

    function approve(address _spender, uint256 _value) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);
}
