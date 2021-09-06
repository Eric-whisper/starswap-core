// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGovPoolType {
    struct PoolTypeLiquidityMint has key, store {}

    struct PoolTypeTeam has key, store {}

    struct PoolTypeInvestor has key, store {}

    struct PoolTypeTechMaintenance has key, store {}

    struct PoolTypeMarket has key, store {}

    struct PoolTypeStockManagement has key, store {}

    struct PoolTypeDaoCrosshain has key, store {}
}
}