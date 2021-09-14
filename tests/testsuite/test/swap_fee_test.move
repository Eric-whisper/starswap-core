//! account: admin, 0x598b8cbfd4536ecbe88aa1cfaffa7a62, 200000 0x1::STC::STC
//! account: feetokenholder, 0x9350502a3af6c617e9a42fa9e306a385, 400000 0x1::STC::STC
//! account: feeadmin, 0xd231d9da8e37fc3d9ff3f576cf978535
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
    use alice::SwapTestHelper::{ETH, USDT, DAI};
    use alice::SwapTestHelper;

    fun token_init(signer: signer) {
        SwapTestHelper::register_and_mint<ETH>(&signer, 18u8, 600000u128);
        SwapTestHelper::register_and_mint<USDT>(&signer, 18u8, 500000u128);
        SwapTestHelper::register_and_mint<DAI>(&signer, 18u8, 200000u128);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: feetokenholder
address alice = {{alice}};
script {
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun fee_token_init(signer: signer) {
        // BX_USDT::init(&signer);
        // BX_USDT::mint(&signer, 500000u128);

        Token::register_token<BX_USDT>(signer, 9);
        Account::do_accept_token<BX_USDT>(signer);
        let token = Token::mint<BX_USDT>(signer, 500000u128);
        Account::deposit_to_self(signer, token);
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
script {
    use 0x1::Account;
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun accept_token(signer: signer) {
        Account::do_accept_token<BX_USDT>(&signer);
    }
}
// check: EXECUTED


//! new-transaction
//! sender: feeadmin
address alice = {{alice}};
script {
    use 0x1::Account;
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun accept_token(signer: signer) {
        Account::do_accept_token<BX_USDT>(&signer);
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

// check: EXECUTED


//! new-transaction
//! sender: feetokenholder
address alice = {{alice}};
address exchanger = {{exchanger}};
script {
    use alice::SwapTestHelper;
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun transfer(signer: signer) {
        SwapTestHelper::safe_transfer<BX_USDT>(&signer, @alice, 300000u128);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: admin
address alice = {{alice}};
script {
    use alice::SwapTestHelper::{ETH, USDT};
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC::STC;
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun register_token_pair(signer: signer) {
        //token pair register must be swap admin account
        TokenSwapRouter::register_swap_pair<ETH, USDT>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<ETH, USDT>(), 111);

        TokenSwapRouter::register_swap_pair<STC, ETH>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<STC, ETH>(), 112);

        TokenSwapRouter::register_swap_pair<STC, BX_USDT>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<STC, BX_USDT>(), 113);

        TokenSwapRouter::register_swap_pair<ETH, BX_USDT>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<ETH, BX_USDT>(), 114);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x1::STC::STC;
    use alice::SwapTestHelper::{ETH, USDT};
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    fun add_liquidity(signer: signer) {
        // for the first add liquidity
        TokenSwapRouter::add_liquidity<ETH, USDT>(&signer, 10000, 20000, 100, 100);
        TokenSwapRouter::add_liquidity<STC, ETH>(&signer, 100000, 30000, 100, 100);

        TokenSwapRouter::add_liquidity<STC, BX_USDT>(&signer, 20000, 5000, 100, 100);
        TokenSwapRouter::add_liquidity<ETH, BX_USDT>(&signer, 50000, 180000, 100, 100);
    }
}

// check: EXECUTED


//! new-transaction
//! sender: exchanger
address alice = {{alice}};
address feeadmin = {{feeadmin}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapLibrary;
    use 0x1::STC::STC;
    use alice::SwapTestHelper::{ETH};
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    use alice::SwapTestHelper;
    use 0x1::Debug;

    fun swap_exact_token_for_token_swap_fee_setup(signer: signer) {
        let amount_x_in = 20000;
        let amount_y_out_min = 10;
        let fee_balance = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);
        assert(fee_balance == 0, 201);

        let (reserve_x, reserve_y) = TokenSwapRouter::get_reserves<STC, ETH>();
        let y_out = TokenSwapLibrary::get_amount_out(amount_x_in, reserve_x, reserve_y); 
        let y_out_without_fee = TokenSwapLibrary::get_amount_out_without_fee(amount_x_in, reserve_x, reserve_y); 
        let swap_fee = y_out_without_fee - y_out;
        TokenSwapRouter::swap_exact_token_for_token<STC, ETH>(&signer, amount_x_in, amount_y_out_min);
        if (! TokenSwap::get_swap_fee_on()){
          TokenSwapRouter::swap_exact_token_for_token_swap_fee_setup<STC, ETH>(amount_x_in, y_out, reserve_x, reserve_y);
        };

        let (reserve_p, reserve_q) = TokenSwapRouter::get_reserves<ETH, BX_USDT>();
        let fee_out = TokenSwapLibrary::get_amount_out_without_fee(swap_fee, reserve_p, reserve_q);
        let fee_balance = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);
        
        Debug::print<u128>(&y_out);
        Debug::print<u128>(&y_out_without_fee);
        Debug::print<u128>(&swap_fee);
        Debug::print<u128>(&fee_out);
        Debug::print<u128>(&fee_balance);
        assert(fee_balance == fee_out, (fee_balance as u64));
        assert(fee_balance > 0, (fee_balance as u64));
    }
}
//the case: token pay for fee and fee token pair exist
// check: EXECUTED



//! new-transaction
//! sender: exchanger
address alice = {{alice}};
address feeadmin = {{feeadmin}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapLibrary;
    use 0x1::STC::STC;
    use alice::SwapTestHelper::{ETH};
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    use alice::SwapTestHelper;
    use 0x1::Debug;

    fun swap_token_for_exact_token_swap_fee_setup(signer: signer) {
        let amount_x_in_max = 8000;
        let amount_y_out = 1000;
        let fee_balance_start = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);
        assert(fee_balance_start > 0, 202);

        let (reserve_x, reserve_y) = TokenSwapRouter::get_reserves<STC, ETH>();
        let x_in = TokenSwapLibrary::get_amount_in(amount_y_out, reserve_x, reserve_y); 
        let x_in_without_fee = TokenSwapLibrary::get_amount_in_without_fee(amount_y_out, reserve_x, reserve_y); 
        let swap_fee = x_in - x_in_without_fee;
        TokenSwapRouter::swap_token_for_exact_token<STC, ETH>(&signer, amount_x_in_max, amount_y_out);
        if (! TokenSwap::get_swap_fee_on()){
            TokenSwapRouter::swap_token_for_exact_token_swap_fee_setup<STC, ETH>(x_in, amount_y_out, reserve_x, reserve_y);
        };

        let (reserve_p, reserve_q) = TokenSwapRouter::get_reserves<STC, BX_USDT>();
        let fee_out = TokenSwapLibrary::get_amount_out_without_fee(swap_fee, reserve_p, reserve_q);
        let fee_balance_end = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);
        let fee_balance_change = fee_balance_end - fee_balance_start;
        
        Debug::print<u128>(&x_in);
        Debug::print<u128>(&x_in_without_fee);
        Debug::print<u128>(&swap_fee);
        Debug::print<u128>(&fee_out);
        Debug::print<u128>(&fee_balance_change);
        assert(fee_balance_change == fee_out, (fee_balance_change as u64));
        assert(fee_balance_change > 0, (fee_balance_change as u64));
    }
}
//the case: token pay for fee and fee token pair exist
// check: EXECUTED



//! new-transaction
//! sender: exchanger
address alice = {{alice}};
address feeadmin = {{feeadmin}};
script {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapLibrary;
    use alice::SwapTestHelper::{ETH, USDT};
    use 0x9350502a3af6c617e9a42fa9e306a385::BX_USDT::BX_USDT;

    use alice::SwapTestHelper;
    use 0x1::Debug;

    fun pay_for_token_and_fee_token_pair_not_exist(signer: signer) {
        let amount_x_in = 20000;
        let amount_y_out_min = 10;
        let fee_balance_start = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);

        let (reserve_x, reserve_y) = TokenSwapRouter::get_reserves<ETH, USDT>();
        let y_out = TokenSwapLibrary::get_amount_out(amount_x_in, reserve_x, reserve_y); 
        let y_out_without_fee = TokenSwapLibrary::get_amount_out_without_fee(amount_x_in, reserve_x, reserve_y); 
        let swap_fee = y_out_without_fee - y_out;
        TokenSwapRouter::swap_exact_token_for_token<ETH, USDT>(&signer, amount_x_in, amount_y_out_min);
        if (! TokenSwap::get_swap_fee_on()){
            TokenSwapRouter::swap_exact_token_for_token_swap_fee_setup<ETH, USDT>(amount_x_in, y_out, reserve_x, reserve_y);
        };

        let fee_balance_end = SwapTestHelper::get_safe_balance<BX_USDT>(@feeadmin);
        let fee_balance_change = fee_balance_end - fee_balance_start;
        
        Debug::print<u128>(&y_out);
        Debug::print<u128>(&y_out_without_fee);
        Debug::print<u128>(&swap_fee);
        assert(fee_balance_change == 0, 204);
    }
}
//the case: token pay for fee and fee token pair not exist
// check: EXECUTED