// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED
//address 0x1 {
//module MockETH {
//    struct MockETH has store {}
//}
//}

//! new-transaction
//! sender: liquidier
script {
    use 0x1::STC;
    use 0x1::MockETH;
    use 0x1::TokenSwap;
    use 0x1::LiquidityToken::LiquidityToken;
    use 0x1::Account;
    use 0x1::TokenMock;
    use 0x1::Token;

    fun main(account: signer) {
        // STC/MockETH = 1:10
        let stc_amount = 1000000;
        let mocketh_amount = 10000000;

        let token_eth = TokenMock::mint_token<MockETH::MockETH>(&account, mocketh_amount);
        let token_stc = TokenMock::mint_token<STC::STC>(&account, stc_amount * 10);

        Account::do_accept_token<LiquidityToken<STC::STC, 0x1::MockETH::MockETH>>(&account);

        let stc = Account::withdraw<STC::STC>(&account, stc_amount);
        let mocketh = Account::withdraw<0x1::MockETH::MockETH>(&account, mocketh_amount);
        let liquidity_token = TokenSwap::mint<STC::STC, 0x1::MockETH::MockETH>(stc, mocketh);
        Account::deposit_to_self(&account, liquidity_token);

        let (x, y) = TokenSwap::get_reserves<STC::STC, MockETH::MockETH>();
        assert(x == stc_amount, 111);
        assert(y == mocketh_amount, 112);

        Token::burn<MockETH::MockETH>(&account, token_eth);
        Token::burn<STC::STC>(&account, token_stc);
    }
}