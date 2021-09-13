//! account: alice, 10000000000000 0x1::STC::STC
//! account: bob, 10000000000000 0x1::STC::STC
//! account: admin, 0x598b8cbfd4536ecbe88aa1cfaffa7a62, 10000000000000 0x1::STC::STC
//! account: liquidier, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock Usdx token
    struct Usdx has copy, drop, store {}
}

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
    use alice::TokenMock::{Usdx};
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Math;
    use 0x1::STC::STC;

    // Deposit to swap pool
    fun main(signer: signer) {
        let precision: u8 = 9; //STC precision is also 9.

        let scaling_factor = Math::pow(10, (precision as u64));// STC/Usdx = 1:5
        let stc_amount: u128 = 1000000 * scaling_factor;
        let usdx_amount: u128 = 1000000 * scaling_factor;

        // Register first
        Token::register_token<Usdx>(&signer, precision);
        Account::do_accept_token<Usdx>(&signer);

        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
        Account::deposit_to_self(&signer, usdx_token);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Add liquidity, STC/Usdx = 1:1
        let amount_stc_desired: u128 = 10000 * scaling_factor;
        let amount_usdx_desired: u128 = 10000 * scaling_factor;
        let amount_stc_min: u128 = stc_amount;
        let amount_usdx_min: u128 = usdx_amount;
        TokenSwapRouter::add_liquidity<STC, Usdx>(
            &signer, amount_stc_desired, amount_usdx_desired, amount_stc_min, amount_usdx_min);

        // check liquidity
        let total_liquidity: u128 = TokenSwapRouter::total_liquidity<STC, Usdx>();
        assert(total_liquidity > 0, 10000);

        // check reverse
        let (reserve_x, reserve_y) = TokenSwapRouter::get_reserves<STC, Usdx>();
        assert(reserve_x >= amount_stc_desired, 10001);
        assert(reserve_y >= amount_usdx_desired, 10001);
   }
}

// check: EXECUTED



//! new-transaction
//! sender: bob
address bob = {{bob}};
address alice = {{alice}};
script {
    use alice::TokenMock::Usdx;
    use 0x1::STC::STC;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Debug;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;

    fun main(signer: signer) {
        let (reserve_x, reserve_y) = TokenSwap::get_reserves<STC, Usdx>();
        Debug::print<u128>(&reserve_x);
        Debug::print<u128>(&reserve_y);
        TokenSwapRouter::swap_exact_token_for_token<STC, Usdx>(&signer, 100, 0);
        let balance = Account::balance<Usdx>(Signer::address_of(&signer));
        assert(balance > 0, 10002);

        TokenSwapRouter::swap_token_for_exact_token<STC, Usdx>(&signer, 10000000, 10000);
        let balance = Account::balance<STC>(Signer::address_of(&signer));
        assert(balance > 0, 10003);
    }
}

// check: EXECUTED