//! account: admin, 0x598b8cbfd4536ecbe88aa1cfaffa7a62, 10000 0x1::STC::STC
////! account: exchanger, 10000000000000 0x1::STC::STC
//! account: alice, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock MyToken token
    struct MyToken has copy, drop, store {}

    // mock Usdx token
    struct Usdx has copy, drop, store {}
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

//TODO support mint for another account test
//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    use alice::TokenMock::{Usdx};
    use 0x1::Account;
    //    use 0x1::Token;
    //    use 0x1::Math;
    fun init_exchanger(signer: signer) {
        //        let precision: u8 = 9; //STC precision is also 9.
        //        let scaling_factor = Math::pow(10, (precision as u64));
        //        let usdx_amount: u128 = 50000 * scaling_factor;
        // Resister and mint Usdx
        //        Token::register_token<Usdx>(&signer, precision);
        Account::do_accept_token<Usdx>(&signer);
        //        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
        //        Account::deposit_to_self(&signer, usdx_token);
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
    use alice::TokenMock::MyToken;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Signer;

    fun register_another_token(signer: signer) {
        Token::register_token<MyToken>(&signer, 6);
        Account::do_accept_token<MyToken>(&signer);
        let old_market_cap = Token::market_cap<MyToken>();
        assert(old_market_cap == 0, 8001);
        let token = Token::mint<MyToken>(&signer, 10000);
        assert(Token::value<MyToken>(&token) == 10000, 8000);
        assert(Token::market_cap<MyToken>() == old_market_cap + 10000, 8001);
        let sender_address = Signer::address_of(&signer);
        Account::deposit(sender_address, token);
        assert(Account::balance<MyToken>(sender_address) == 10000, 8003);
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

    fun add_liquidity(signer: signer) {
        // for the first add liquidity
        TokenSwapRouter::add_liquidity<STC::STC, TokenMock::Usdx>(&signer, 10000, 10000 * 10000, 10, 10);
        let total_liquidity = TokenSwapRouter::total_liquidity<STC::STC, TokenMock::Usdx>();
        assert(total_liquidity == 1000000 - 1000, (total_liquidity as u64));
        TokenSwapRouter::add_liquidity<STC::STC, TokenMock::Usdx>(&signer, 10000, 10000 * 10000, 10, 10);
        let total_liquidity = TokenSwapRouter::total_liquidity<STC::STC, TokenMock::Usdx>();
        assert(total_liquidity == (1000000 - 1000) * 2, (total_liquidity as u64));
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
    use 0x1::Account;
    use 0x1::Signer;

    fun remove_liquidity(signer: signer) {
        TokenSwapRouter::remove_liquidity<STC::STC, TokenMock::Usdx>(&signer, 10000, 10, 10);
        let _token_balance = Account::balance<TokenMock::Usdx>(Signer::address_of(&signer));
        let expected = (10000 * 10000) * 2 * 10000 / ((1000000 - 1000) * 2);
        //assert(token_balance == expected, (token_balance as u64));

        //let y = to_burn_value * y_reserve / total_supply;
        let (stc_reserve, usdx_reserve) = TokenSwapRouter::get_reserves<STC::STC, TokenMock::Usdx>();
        assert(stc_reserve == 10000 * 2 - 10000 * 2 * 10000 / ((1000000 - 1000) * 2), (stc_reserve as u64));
        assert(usdx_reserve == 10000 * 10000 * 2 - expected, (usdx_reserve as u64));
    }
}
// check: EXECUTED


//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC;
    use alice::TokenMock;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Debug;

    fun swap_exact_token_for_token(signer: signer) {
        let (stc_reserve, token_reserve) = TokenSwapRouter::get_reserves<STC::STC, TokenMock::Usdx>();
        Debug::print<u128>(&stc_reserve);
        Debug::print<u128>(&token_reserve);
        TokenSwapRouter::swap_exact_token_for_token<STC::STC, TokenMock::Usdx>(&signer, 1000, 0);
        let token_balance = Account::balance<TokenMock::Usdx>(Signer::address_of(&signer));
        let expected_token_balance = TokenSwapRouter::get_amount_out(1000, stc_reserve, token_reserve);
        Debug::print<u128>(&token_balance);
        assert(token_balance == expected_token_balance, (token_balance as u64));
    }
}
// check: EXECUTED

//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC;
    use alice::TokenMock;
    use 0x1::Account;
    use 0x1::Signer;

    fun swap_token_for_exact_token(signer: signer) {
        let stc_balance_before = Account::balance<STC::STC>(Signer::address_of(&signer));
        let (stc_reserve, token_reserve) = TokenSwapRouter::get_reserves<STC::STC, TokenMock::Usdx>();
        TokenSwapRouter::swap_token_for_exact_token<STC::STC, TokenMock::Usdx>(&signer, 30, 100000);
        let stc_balance_after = Account::balance<STC::STC>(Signer::address_of(&signer));

        let expected_balance_change = TokenSwapRouter::get_amount_in(100000, stc_reserve, token_reserve);
        assert(stc_balance_before - stc_balance_after == expected_balance_change, (expected_balance_change as u64));
    }
}
// check: EXECUTED
