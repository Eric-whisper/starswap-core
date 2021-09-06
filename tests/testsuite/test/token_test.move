//! account: alice, 50000 0x1::STC::STC
//! account: admin

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    struct MyToken has copy, drop, store { }
}

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x1::Debug;
    use alice::TokenMock::MyToken;
    use 0x1::STC::STC;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap;

    fun main(_signer: signer) {
        let ret = TokenSwap::compare_token<STC, MyToken>();
        Debug::print<u8>(&ret);
        assert(ret == 1, 10000);
    }
}
// check: EXECUTED
