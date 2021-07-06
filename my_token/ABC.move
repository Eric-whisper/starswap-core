// address 0x2 {
address 0x4b2b6e26ee6919d6878c05ae2c3572da {
/// ABC is a test token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module ABC {
    // use 0x1::Token::{Self, Token};
    // use 0x1::Dao;

    use 0x1::Token;
    use 0x1::Account;

    /// ABC token marker.
    struct ABC has copy, drop, store { }

    /// precision of ABC token.
    const PRECISION: u8 = 18;

    /// ABC initialization.
    public(script) fun init(account: signer) {
         Token::register_token<ABC>(&account, PRECISION);
         Account::do_accept_token<ABC>(&account);
    }

    public(script) fun mint(account: signer, amount: u128) {
        let token = Token::mint<ABC>(&account, amount);
        Account::deposit_to_self<ABC>(&account, token)
    }

    /// Returns true if `TokenType` is `ABC::ABC`
    public fun is_abc<TokenType: store>(): bool {
        Token::is_same_token<ABC, TokenType>()
    }

    spec is_abc {
    }

    /// Return ABC token address.
    public fun token_address(): address {
        Token::token_address<ABC>()
    }

    spec token_address {
    }
}
}