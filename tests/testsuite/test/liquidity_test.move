//! account: alice, 10000000000000 0x1::STC::STC
//! account: joe
//! account: admin, 0x81144d60492982a45ba93fba47cae988, 10000000000000 0x1::STC::STC
//! account: liquidier, 10000000000000 0x1::STC::STC

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
address liquidier = {{liquidier}};
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

//        let usdx_token_2 = Token::mint<Usdx>(&signer, usdx_amount);
//        Account::deposit(@liquidier, usdx_token_2);
    }
}
// check: EXECUTED

////! new-transaction
////! sender: liquidier
//address alice = {{alice}};
//script {
//    use alice::TokenMock::{Usdx};
//    use 0x1::Account;
//    use 0x1::Token;
//    use 0x1::Math;
//    fun init_liquidier(signer: signer) {
//        let precision: u8 = 9; //STC precision is also 9.
//        let scaling_factor = Math::pow(10, (precision as u64));
//        let usdx_amount: u128 = 50000 * scaling_factor;
//        // mint Usdx
//        Account::do_accept_token<Usdx>(&signer);
//        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
//        Account::deposit_to_self(&signer, usdx_token);
//    }
//}
//// check: EXECUTED


//! new-transaction
//! sender: admin
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap;
    use 0x1::STC::STC;
    fun register_token_pair(signer: signer) {
        //token pair register must be swap admin account
        TokenSwap::register_swap_pair<STC, Usdx>(&signer);
        assert(TokenSwap::swap_pair_exists<STC, Usdx>(), 111);
    }
}
// check: EXECUTED


////! new-transaction
////! sender: alice
//address alice = {{alice}};
//script {
//    use alice::TokenMock::{Usdx};
//    use 0x81144d60492982a45ba93fba47cae988::TokenSwap;
//    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
//    use 0x1::Account;
//    use 0x1::STC::STC;
////    use 0x1::Math;
//    fun mint(signer: signer) {
//        // STC/Usdx = 1:2
//        let stc_amount = 10000;
//        let usdx_amount = 20000;
//
//        // liquidity register and mint
//        let stc_token = Account::withdraw<STC>(&signer, stc_amount);
//        let usdx_token = Account::withdraw<Usdx>(&signer, usdx_amount);
//        Account::do_accept_token<LiquidityToken<STC, Usdx>>(&signer);
//        let liquidity_token = TokenSwap::mint<STC, Usdx>(stc_token, usdx_token);
//        Account::deposit_to_self(&signer, liquidity_token);
//
//        let (x, y) = TokenSwap::get_reserves<STC, Usdx>();
//        assert(x == stc_amount, 111);
//        assert(y == usdx_amount, 112);
//    }
//}
//// check: EXECUTED

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Math;
    use 0x1::STC::STC;

    fun add_liquidity_and_swap(signer: signer) {
        let precision: u8 = 9; //STC precision is also 9.
        let scaling_factor = Math::pow(10, (precision as u64));
        // STC/Usdx = 1:5
        let stc_amount: u128 = 10000 * scaling_factor;
        let usdx_amount: u128 = 50000 * scaling_factor;

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Add liquidity, STC/Usdx = 1:5
        let amount_stc_desired: u128 = 10 * scaling_factor;
        let amount_usdx_desired: u128 = 50 * scaling_factor;
        let amount_stc_min: u128 = 1 * scaling_factor;
        let amount_usdx_min: u128 = 1 * scaling_factor;
        TokenSwapRouter::add_liquidity<STC, Usdx>(&signer,
        amount_stc_desired, amount_usdx_desired, amount_stc_min, amount_usdx_min);
        let total_liquidity: u128 = TokenSwapRouter::total_liquidity<STC, Usdx>();
        assert(total_liquidity > amount_stc_min, 10000);
        // Balance verify
        assert(Account::balance<STC>(Signer::address_of(&signer)) ==
        (stc_amount - amount_stc_desired), 10001);
        assert(Account::balance<Usdx>(Signer::address_of(&signer)) ==
        (usdx_amount - amount_usdx_desired), 10002);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Swap token pair, put 1 STC, got 5 Usdx
        let pledge_stc_amount: u128 = 1 * scaling_factor;
        let pledge_usdx_amount: u128 = 5 * scaling_factor;
        TokenSwapRouter::swap_exact_token_for_token<STC, Usdx>(
        &signer, pledge_stc_amount, pledge_stc_amount);
        assert(Account::balance<STC>(Signer::address_of(&signer)) ==
        (stc_amount - amount_stc_desired - pledge_stc_amount), 10004);
        // TODO: To verify why swap out less than ratio swap out
        assert(Account::balance<Usdx>(Signer::address_of(&signer)) <=
        (usdx_amount - amount_usdx_desired + pledge_usdx_amount), 10005);
    }
}

// check: EXECUTED