// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGovScript {

    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov;

    /// Initial as genesis that will create pool list by Starswap Ecnomic Model list
    public(script) fun genesis_initialize(account: signer) {
        TokenSwapGov::genesis_initialize(&account);
    }

    /// Called by user, the user claim pool have stake asset
    public(script) fun claim<PoolType: store>(account: signer) {
        TokenSwapGov::claim<PoolType>(&account);
    }

    /// Called by admin, increase or decrease linear asset value
    public fun admin_add_linear_asset<PoolType: store>(account: signer,
                                                       beneficiary: address,
                                                       amount: u128){
        TokenSwapGov::admin_add_linear_asset<PoolType>(&account, beneficiary, amount);
    }

    /// Harverst TBD by given pool type, call ed by user
    public fun harvest<PoolType: store>(account: signer) {
        TokenSwapGov::harvest<PoolType>(&account);
    }
}
}