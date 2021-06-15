// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

// register a token pair STC/Token1
//! new-transaction
//! sender: admin
address 0x1 {
module Token1 {
    struct Token1 {}
}
}

script {
    use 0x1::TokenSwap;
    use 0x1::Token1;
    use 0x1::Token;
    use 0x1::STC;

    fun main(signer: &signer) {
        Token::register_token<Token1::Token1>(signer, 3);
        TokenSwap::register_swap_pair<STC::STC, Token1::Token1>(signer);
    }
}