//! account: alice, 10000000000000 0x1::STC::STC

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    // mock MyToken token
    struct MyToken has copy, drop, store { }

    // mock Usdx token
    struct Usdx has copy, drop, store { }
}
