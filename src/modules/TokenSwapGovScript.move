// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGovScript {

    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov;

    /// Initial as genesis that will create pool list by Starswap Ecnomic Model list
    public(script) fun genesis_initialize(account: signer) {
        TokenSwapGov::genesis_initialize(&account);
    }

    /// Harverst TBD by given pool type, call ed by user
    public(script) fun dispatch<PoolType: store>(account: signer, acceptor: address, amount: u128) {
        TokenSwapGov::dispatch<PoolType>(&account, acceptor, amount);
    }
}
}