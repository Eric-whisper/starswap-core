module Pdd {
     use 0x1::Token;
     use 0x1::Account;

     struct Pdd has copy, drop, store { }

     public(script) fun init(account: signer) {
         Token::register_token<Pdd>(&account, 3);
         Account::do_accept_token<Pdd>(&account);
     }

     public(script) fun mint(account: signer, amount: u128) {
        let token = Token::mint<Pdd>(&account, amount);
        Account::deposit_to_self<Pdd>(&account, token)
     }
}
