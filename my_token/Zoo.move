// address 0x2 {
/// Zoo is a test token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module Zoo {
    // use 0x1::Token::{Self, Token};
    // use 0x1::Dao;

    use 0x1::Token;
    use 0x1::Account;

    /// Zoo token marker.
    struct Zoo has copy, drop, store { }

    /// precision of Zoo token.
    const PRECISION: u8 = 18;

    /// Zoo initialization.
    public(script) fun init(account: signer) {
         Token::register_token<Zoo>(&account, PRECISION);
         Account::do_accept_token<Zoo>(&account);
    }

    public(script) fun mint(account: signer, amount: u128) {
        let token = Token::mint<Zoo>(&account, amount);
        Account::deposit_to_self<Zoo>(&account, token)
    }

    /// Returns true if `TokenType` is `Zoo::Zoo`
    public fun is_zoo<TokenType: store>(): bool {
        Token::is_same_token<Zoo, TokenType>()
    }

    spec fun is_zoo {
    }

    /// Return Zoo token address.
    public fun token_address(): address {
        Token::token_address<Zoo>()
    }

    spec fun token_address {
    }
}
// }