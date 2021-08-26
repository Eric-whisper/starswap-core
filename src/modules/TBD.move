// address 0x2 {
address 0x81144d60492982a45ba93fba47cae988 {
/// TBD is a governance token of Starcoin blockchain DAPP.
/// It uses apis defined in the `Token` module.
module TBD {
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Signer;

    /// TBD token marker.
    struct TBD has copy, drop, store { }

    /// precision of TBD token.
    const PRECISION: u8 = 9;

    const ERROR_NOT_GENESIS_ACCOUNT: u64 = 10001;

    /// TBD initialization.
    public fun init(account: signer) {
        Token::register_token<TBD>(&account, PRECISION);
        Account::do_accept_token<TBD>(&account);
    }

    // Mint function, block ability of mint and burn after execution
    public fun mint(account: &signer, amount: u128): (Token::MintCapability<TBD>, Token::BurnCapability<TBD>) {
        let token = Token::mint<TBD>(account, amount);
        Account::deposit_to_self<TBD>(account, token);

        let mint_cap = Token::remove_mint_capability(account);
        let burn_cap = Token::remove_burn_capability(account);
        (mint_cap, burn_cap)
    }

    /// Returns true if `TokenType` is `TBD::TBD`
    public fun is_tbd<TokenType: store>(): bool {
        Token::is_same_token<TBD, TokenType>()
    }

    spec is_abc {
    }

    public fun assert_genesis_address(account : &signer) {
        assert(Signer::address_of(account) == token_address(), ERROR_NOT_GENESIS_ACCOUNT);
    }

    /// Return TBD token address.
    public fun token_address(): address {
        Token::token_address<TBD>()
    }

    spec token_address {
    }

    /// Return TBD precision.
    public fun precision(): u8 {
        PRECISION
    }

    spec precision {
    }
}
}