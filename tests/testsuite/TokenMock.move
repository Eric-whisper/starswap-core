//! account: alice, 10000000000000 0x1::STC::STC

//! sender: alice
address alice = {{alice}};
module alice::SwapTestHelper {
   use 0x1::Token;
   use 0x1::Account;

   // mock MyToken token
   struct MyToken has copy, drop, store { }

   // mock Usdx token
   struct Usdx has copy, drop, store { }

   public fun register_and_mint<T: store>(signer: &signer, precision: u8, mint_amount: u128){
       // Resister and mint Token
       Token::register_token<T>(signer, precision);
       Account::do_accept_token<T>(signer);
       let token = Token::mint<T>(signer, mint_amount);
       Account::deposit_to_self(signer, token);
   }
}

// check: EXECUTED