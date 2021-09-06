//! account: admin, 0x598b8cbfd4536ecbe88aa1cfaffa7a62, 10000 0x1::STC::STC
////! account: exchanger, 10000000000000 0x1::STC::STC
//! account: alice, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock MyToken token
    struct MyToken has copy, drop, store { }

    // mock Usdx token
    struct Usdx has copy, drop, store { }
}

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Math;
    fun init(signer: signer) {
        let precision: u8 = 9; //STC precision is also 9.
        let scaling_factor = Math::pow(10, (precision as u64));
        let usdx_amount: u128 = 50000 * scaling_factor;
        // Resister and mint Usdx
        Token::register_token<Usdx>(&signer, precision);
        Account::do_accept_token<Usdx>(&signer);
        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
        Account::deposit_to_self(&signer, usdx_token);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: admin
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;
    use 0x1::STC::STC;
    fun register_token_pair(signer: signer) {
        //token pair register must be swap admin account
        TokenSwap::register_swap_pair<STC, Usdx>(&signer);
        assert(TokenSwap::swap_pair_exists<STC, Usdx>(), 111);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC;
    use alice::TokenMock;
    fun add_liquidity_overflow(signer: signer) {
        // for the first add liquidity
        TokenSwapRouter::add_liquidity<STC::STC, TokenMock::Usdx>(&signer, 10, 4000, 10, 10);
        let total_liquidity = TokenSwapRouter::total_liquidity<STC::STC, TokenMock::Usdx>();
        assert(total_liquidity == 200 - 1000, 3001);
        TokenSwapRouter::add_liquidity<STC::STC, TokenMock::Usdx>(&signer, 10, 4000, 10, 10);
        let total_liquidity = TokenSwapRouter::total_liquidity<STC::STC, TokenMock::Usdx>();
        assert(total_liquidity == (200 - 1000)*2, 3002);
    }
}
// check: ARITHMETIC_ERROR