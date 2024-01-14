// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

contract SafeDogeElonShibMoon is ERC20 {
    constructor()
    ERC20("SafeDogeElonShibMoon", "SDE", 18) {
        _mint(msg.sender, type(uint256).max);
    }
}