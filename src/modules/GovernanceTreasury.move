// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module GovernanceTreasury {
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Treasury;
    use 0x1::Option;
    use 0x1::Account;
    use 0x1::Timestamp;

    struct WithdrawCapability<PoolType, GovTokenT> {}

    public fun initialize<PoolType: store,
                          TokenT: store>(treasury: Token::Token<TokenT>): WithdrawCapability<PoolType, TokenT> {}

    public fun withdraw_with_capability<PoolType: store,
                                        TokenT: store>(_cap: &WithdrawCapability<PoolType, TokenT>,
                                                       amount: u128): Token::Token<TokenT> {}
}
}