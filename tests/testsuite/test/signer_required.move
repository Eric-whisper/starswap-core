//! account: alice, 10000000000000 0x1::STC::STC

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock Usdx token
    struct Usdx has copy, drop, store {}
    // mock MyToken token
    struct Usdy has copy, drop, store {}
}


//! new-transaction
//! sender: genesis
script {
//    use alice::TokenMock::{Usdx};
//    use alice::TokenMock::{Usdy};
    use 0x1::TokenSwap;

    fun intialize(signer: signer) {
        //token pair register must be swap admin account
        TokenSwap::initialize(&signer);
}
}

//! new-transaction
//! sender: alice
script {
    use alice::TokenMock::{Usdx};
    use alice::TokenMock::{Usdy};
    use 0x1::TokenSwap;

    fun intialize(signer: signer) {
        //token pair register must be swap admin account
        TokenSwap::register_swap_pair<Usdx, Usdy>(&signer);
        assert(TokenSwap::swap_pair_exists<Usdx, Usdy>(), 10001);
    }
}

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use alice::TokenMock::{Usdy};
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Math;
    use 0x1::TokenSwapRouter;

    fun init(signer: signer) {
        let precision: u8 = 9; //STC precision is also 9.
        let scaling_factor = Math::pow(10, (precision as u64));
        let usdx_amount: u128 = 50000 * scaling_factor;
        let usdy_amount: u128 = 50000 * scaling_factor;

        // Resister and mint Usdx
        Token::register_token<Usdx>(&signer, precision);
        Account::do_accept_token<Usdx>(&signer);
        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
        Account::deposit_to_self(&signer, usdx_token);

        // Resister and mint Usdy
        Token::register_token<Usdy>(&signer, precision);
        Account::do_accept_token<Usdy>(&signer);
        let usdy_token = Token::mint<Usdy>(&signer, usdy_amount);
        Account::deposit_to_self(&signer, usdy_token);

        TokenSwapRouter::add_liquidity<Usdx, Usdy>(&signer, usdy_amount, usdx_amount, 10, 10);
        let total_liquidity = TokenSwapRouter::total_liquidity<Usdy, Usdx>();
        assert(total_liquidity > 0, 10002);
    }
}