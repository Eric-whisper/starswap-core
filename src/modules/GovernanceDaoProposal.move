// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module GovernanceDaoProposal {

    use 0x1::Governance;
    use 0x1::Dao;

    public fun plugin(account: &signer, cap: Governance::ParameterModifyCapability) {}

    /// Start a proposal while an governance need changing parameter
    public fun submit_propose() {}

    /// Perform propose after propose has completed
    public fun perform_propose() {}
}
}