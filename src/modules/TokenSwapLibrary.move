// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
module TokenSwapLibrary {

    const ERROR_ROUTER_PARAMETER_INVALID: u64 = 1001;

    /// Return amount_y needed to provide liquidity given `amount_x`
    public fun quote(amount_x: u128, reserve_x: u128, reserve_y: u128): u128 {
        assert(amount_x > 0, ERROR_ROUTER_PARAMETER_INVALID);
        assert(reserve_x > 0 && reserve_y > 0, ERROR_ROUTER_PARAMETER_INVALID);
        let amount_y = amount_x * reserve_y / reserve_x;
        amount_y
    }

    public fun get_amount_in(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        let numerator = reserve_in * amount_out * 1000;
        let denominator = (reserve_out - amount_out) * 997;
        numerator / denominator + 1
    }

    public fun get_amount_out(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_in > 0, ERROR_ROUTER_PARAMETER_INVALID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        let amount_in_with_fee = amount_in * 997;
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in * 1000 + amount_in_with_fee;
        numerator / denominator
    }

    public fun get_amount_in_without_fee(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        let numerator = reserve_in * amount_out;
        let denominator = (reserve_out - amount_out);
        numerator / denominator + 1
    }

    public fun get_amount_out_without_fee(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_in > 0, ERROR_ROUTER_PARAMETER_INVALID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVALID);
        let numerator = amount_in * reserve_out;
        let denominator = reserve_in  + amount_in;
        numerator / denominator
    }

}
}