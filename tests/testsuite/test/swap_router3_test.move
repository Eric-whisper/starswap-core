//! account: admin, 0x598b8cbfd4536ecbe88aa1cfaffa7a62, 200000 0x1::STC::STC
//! account: exchanger, 100000 0x1::STC::STC
//! account: alice, 500000 0x1::STC::STC

//! sender: alice
address alice = {{alice}};
module alice::SwapTestHelper {
    use 0x1::Token;
    use 0x1::Account;

    // mock ETH token
    struct ETH has copy, drop, store {}

    // mock USDT token
    struct USDT has copy, drop, store {}

    // mock DAI token
    struct DAI has copy, drop, store {}

    // mock BTC token
    struct BTC has copy, drop, store {}

    // mock DOT token
    struct DOT has copy, drop, store {}

    public fun register_and_mint<T: store>(signer: &signer, precision: u8, mint_amount: u128){
        // Resister and mint Token
        Token::register_token<T>(signer, precision);
        Account::do_accept_token<T>(signer);
        let token = Token::mint<T>(signer, mint_amount);
        Account::deposit_to_self(signer, token);
    }

    public fun safe_transfer<T: store>(signer: &signer, token_address: address, token_amount: u128){
        let token = Account::withdraw<T>(signer, token_amount);
         Account::deposit(token_address, token);
    }

    public fun get_safe_balance<T: store>(token_address: address): u128{
        let token_balance: u128 = 0;
        if (Account::is_accepts_token<T>(token_address)) {
            token_balance = Account::balance<T>(token_address);
        };
        token_balance
    }
}

// check: EXECUTED

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use alice::SwapTestHelper::{ETH, USDT, DAI, BTC};
    use alice::SwapTestHelper;

    fun token_init(signer: signer) {
        SwapTestHelper::register_and_mint<ETH>(&signer, 18u8, 600000u128);
        SwapTestHelper::register_and_mint<USDT>(&signer, 18u8, 500000u128);
        SwapTestHelper::register_and_mint<DAI>(&signer, 18u8, 200000u128);
        SwapTestHelper::register_and_mint<BTC>(&signer, 9u8, 100000u128);
    }
}

// check: EXECUTED

//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    use alice::SwapTestHelper::{ETH};
    use 0x1::Account;

    fun accept_token(signer: signer) {
        Account::do_accept_token<ETH>(&signer);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: alice
address alice = {{alice}};
address exchanger = {{exchanger}};
script {
    use alice::SwapTestHelper::{ETH};
    use alice::SwapTestHelper;

    fun transfer(signer: signer) {
        SwapTestHelper::safe_transfer<ETH>(&signer, @exchanger, 100000u128);
    }
}


//! new-transaction
//! sender: admin
address alice = {{alice}};
script {
    use alice::SwapTestHelper::{ETH, USDT, DAI, BTC};
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC::STC;

    fun register_token_pair(signer: signer) {
        //token pair register must be swap admin account
        TokenSwapRouter::register_swap_pair<ETH, USDT>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<ETH, USDT>(), 111);

        TokenSwapRouter::register_swap_pair<USDT, DAI>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<USDT, DAI>(), 112);

        TokenSwapRouter::register_swap_pair<DAI, BTC>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<DAI, BTC>(), 113);

        TokenSwapRouter::register_swap_pair<STC, ETH>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<STC, ETH>(), 114);

        TokenSwapRouter::register_swap_pair<BTC, ETH>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<BTC, ETH>(), 115);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC::STC;
    use alice::SwapTestHelper::{ETH, USDT, DAI, BTC};

    fun add_liquidity(signer: signer) {
        // for the first add liquidity
        TokenSwapRouter::add_liquidity<ETH, USDT>(&signer, 10000, 20000, 100, 100);
        TokenSwapRouter::add_liquidity<USDT, DAI>(&signer, 20000, 30000, 100, 100);
        TokenSwapRouter::add_liquidity<DAI, BTC>(&signer, 50000, 4000, 100, 100);
        TokenSwapRouter::add_liquidity<STC, ETH>(&signer, 100000, 20000, 100, 100);
        TokenSwapRouter::add_liquidity<ETH, BTC>(&signer, 80000, 5000, 100, 100);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter3;
    use alice::SwapTestHelper::{ETH, DOT, BTC, DAI};

    fun swap_pair_not_exist(signer: signer) {
        let amount_x_in = 200;
        let amount_y_out_min = 500;
        TokenSwapRouter3::swap_exact_token_for_token<ETH, BTC, DOT, DAI>(&signer, amount_x_in, amount_y_out_min);
    }
}
// when swap router dost not exist, swap encounter failure
// check: EXECUTION_FAILURE
// check: MISSING_DATA


//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {

    // use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    // use alice::SwapTestHelper::{ETH};

    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter3;
    use 0x1::STC::STC;
    use alice::SwapTestHelper::{ETH, USDT, DAI};

    use alice::SwapTestHelper;
    use 0x1::Signer;
    use 0x1::Debug;

    fun swap_exact_token_for_token(signer: signer) {
        let amount_x_in = 8000;
        let amount_y_out_min = 10;
        let token_balance = SwapTestHelper::get_safe_balance<DAI>(Signer::address_of(&signer));
        assert(token_balance == 0, 201);

        let (r_out, t_out, expected_token_balance) = TokenSwapRouter3::get_amount_out<STC, ETH, USDT, DAI>(amount_x_in); 
        TokenSwapRouter3::swap_exact_token_for_token<STC, ETH, USDT, DAI>(&signer, amount_x_in, amount_y_out_min);

        // TokenSwapRouter::swap_exact_token_for_token<STC, ETH>(&signer, amount_x_in, r_out);
        // TokenSwapRouter::swap_exact_token_for_token<ETH, USDT>(&signer, r_out, t_out);
        // TokenSwapRouter::swap_exact_token_for_token<USDT, DAI>(&signer, t_out, amount_y_out_min);

        let token_balance = SwapTestHelper::get_safe_balance<DAI>(Signer::address_of(&signer));
        Debug::print<u128>(&r_out);
        Debug::print<u128>(&t_out);
        Debug::print<u128>(&token_balance);

        Debug::print<u128>(&amount_y_out_min);
        Debug::print<u128>(&expected_token_balance);
        assert(token_balance == expected_token_balance, (token_balance as u64));
        assert(token_balance >= amount_y_out_min, (token_balance as u64));
    }
}

// check: EXECUTED


//! new-transaction
//! sender: exchanger
address alice = {{alice}};
script {
    // use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    // use alice::SwapTestHelper::{ETH};

    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter3;
    use alice::SwapTestHelper::{ETH, USDT, DAI, BTC};

    use alice::SwapTestHelper;
    use 0x1::Signer;
    use 0x1::Debug;

    fun swap_token_for_exact_token(signer: signer) {
        let amount_x_in_max = 20000;
        let amount_y_out = 500;
        let token_balance = SwapTestHelper::get_safe_balance<BTC>(Signer::address_of(&signer));
        assert(token_balance == 0, 201);

        let (t_in, r_in, x_in) = TokenSwapRouter3::get_amount_in<ETH, USDT, DAI, BTC>(amount_y_out); 
        TokenSwapRouter3::swap_token_for_exact_token<ETH, USDT, DAI, BTC>(&signer, amount_x_in_max, amount_y_out);

        // TokenSwapRouter::swap_token_for_exact_token<ETH, USDT>(&signer, amount_x_in_max, r_in);
        // TokenSwapRouter::swap_token_for_exact_token<USDT, DAI>(&signer, r_in, t_in);
        // TokenSwapRouter::swap_token_for_exact_token<DAI, BTC>(&signer, t_in, amount_y_out);

        let token_balance = SwapTestHelper::get_safe_balance<BTC>(Signer::address_of(&signer));   
        Debug::print<u128>(&x_in);
        Debug::print<u128>(&r_in);
        Debug::print<u128>(&t_in);
        Debug::print<u128>(&token_balance);
        Debug::print<u128>(&amount_x_in_max);
        assert(token_balance == amount_y_out, (token_balance as u64));
        assert(x_in <= amount_x_in_max, (token_balance as u64));
    }
}

// check: EXECUTED