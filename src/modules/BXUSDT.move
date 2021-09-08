address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
/// BX_USDT is a test token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module BX_USDT {
    // use 0x1::Token::{Self, Token};
    // use 0x1::Dao;

    use 0x1::Token;
    use 0x1::Account;

    /// BX_USDT token marker.
    struct BX_USDT has copy, drop, store {}

    /// precision of BX_USDT token.
    const PRECISION: u8 = 9;

    /// BX_USDT initialization.
    public ( script ) fun init(account: signer) {
        Token::register_token<BX_USDT>(&account, PRECISION);
        Account::do_accept_token<BX_USDT>(&account);
    }

    public ( script ) fun mint(account: signer, amount: u128) {
        let token = Token::mint<BX_USDT>(&account, amount);
        Account::deposit_to_self<BX_USDT>(&account, token)
    }

    /// Returns true if `TokenType` is `BX_USDT::BX_USDT`
    public fun is_BX_USDT<TokenType: store>(): bool {
        Token::is_same_token<BX_USDT, TokenType>()
    }

    spec is_bx_usdt {}

    /// Return BX_USDT token address.
    public fun token_address(): address {
        Token::token_address<BX_USDT>()
    }

    spec token_address {}
}
}