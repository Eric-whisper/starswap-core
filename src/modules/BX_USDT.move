address 0x49156896A605F092ba1862C50a9036c9 {
module BX_USDT {
    use 0x1::Token;
    use 0x1::Account;

    /// BX_USDT token marker.
    struct BX_USDT has copy, drop, store {}

    /// precision of BX_USDT token.
    const PRECISION: u8 = 9;

    /// BX_USDT initialization.
    public fun init(account: &signer) {
        Token::register_token<BX_USDT>(account, PRECISION);
        Account::do_accept_token<BX_USDT>(account);
    }

    public fun mint(account: &signer, amount: u128) {
        let token = Token::mint<BX_USDT>(account, amount);
        Account::deposit_to_self<BX_USDT>(account, token)
    }
}

module BXUSDTScripts {
    use 0x49156896A605F092ba1862C50a9036c9::BX_USDT;

    public(script) fun init(account: signer) {
        BX_USDT::init(&account);
    }

    public(script) fun mint(account: signer, amount: u128) {
        BX_USDT::mint(&account, amount);
    }
}

}