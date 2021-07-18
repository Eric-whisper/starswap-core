//! account: alice, 10000000000000 0x1::STC::STC
//! account: joe
//! account: admin, 0x81144d60492982a45ba93fba47cae988, 10000000000000 0x1::STC::STC
//! account: liquidier, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock Usdx token
    struct Usdx has copy, drop, store { }
}

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

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x1::Debug;
    use alice::TokenMock::Usdx;
    use 0x1::STC::STC;
    use 0x1::Math;
    use 0x1::Token;
    use 0x1::Account;
    //use 0x81144d60492982a45ba93fba47cae988::TokenSwap;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;

    fun main(signer: signer) {
        let precision: u8 = 9; //STC precision is also 9.

        let scaling_factor = Math::pow(10, (precision as u64));// STC/Usdx = 1:5
        let stc_amount: u128 = 1000 * scaling_factor;
        let usdx_amount: u128 = 1000 * scaling_factor;

        // Register first
        Token::register_token<Usdx>(&signer, precision);
        Account::do_accept_token<Usdx>(&signer);
        let usdx_token = Token::mint<Usdx>(&signer, usdx_amount);
        Account::deposit_to_self(&signer, usdx_token);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Add liquidity, STC/Usdx = 1:1
        let amount_stc_desired: u128 = 1 * scaling_factor;
        let amount_usdx_desired: u128 = 1 * scaling_factor;
        let amount_stc_min: u128 = stc_amount;
        let amount_usdx_min: u128 = usdx_amount;
        TokenSwapRouter::add_liquidity<STC, Usdx>(&signer,
            amount_stc_desired, amount_usdx_desired, amount_stc_min, amount_usdx_min);
        let total_liquidity: u128 = TokenSwapRouter::total_liquidity<STC, Usdx>();
        assert(total_liquidity > 0, 10000);

        let (reserve_x, reserve_y) = TokenSwapRouter::get_reserves<STC, Usdx>();
        //Debug::print<u128>(&reserve_x);
        //Debug::print<u128>(&reserve_y);
        assert(reserve_x >= amount_stc_desired, 10001);
        // assert(reserve_y >=, 10002);

        let amount_out_1 = TokenSwapRouter::get_amount_out(10 * scaling_factor, reserve_x, reserve_y);
        Debug::print<u128>(&amount_out_1);
        // assert(1 * scaling_factor >= (1 * scaling_factor * reserve_y) / reserve_x * (997 / 1000), 1003);

        let amount_out_2 = TokenSwapRouter::quote(amount_stc_desired, reserve_x, reserve_y);
        Debug::print<u128>(&amount_out_2);
        // assert(amount_out_2 <= amount_usdx_desired, 1004);

        let amount_out_3 = TokenSwapRouter::get_amount_in(100, 100000000, 10000000000);
        Debug::print<u128>(&amount_out_3);
        //assert(amount_out_3 >= amount_stc_desired, 1005);

    }
}