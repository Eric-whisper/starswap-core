// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module GovernanceDaoProposal {

    use 0x1::Governance;
    use 0x1::Dao;
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Errors;

    const ERR_NOT_AUTHORIZED: u64 = 401;

    /// A wrapper of `Governance::ParameterModifyCapability`.
    struct GovernanceCapability<PoolType, TokenT> has key {
        cap: Governance::ParameterModifyCapability,
    }

    struct GovernanceProposalAction<PoolType> has copy, drop, store {
        period_release_amount: u128,
    }

    /// Add dao of governance ability
    public fun plugin<PoolType: copy + drop + store,
                      TokenT: copy + drop + store>(account: &signer, cap: Governance::ParameterModifyCapability) {
        let token_issuer = Token::token_address<TokenT>();
        assert(Signer::address_of(account) == token_issuer, Errors::requires_address(ERR_NOT_AUTHORIZED));

        move_to(account, GovernanceCapability<PoolType, TokenT> { cap })
    }

    spec plugin {
        pragma aborts_if_is_partial = false;
        let sender = Signer::address_of(account);
        aborts_if sender != Token::SPEC_TOKEN_TEST_ADDRESS();
        aborts_if exists<GovernanceProposalAction<TokenT>>(sender);
        ensures exists<GovernanceProposalAction<TokenT>>(sender);
    }

    /// Start a proposal while an governance need changing parameter
    public fun submit_proposal<PoolType: copy + drop + store,
                               TokenT: copy + drop + store>(
        account: &signer,
        period_release_amount: u128,
        exec_delay: u64) {
        Dao::propose<TokenT, GovernanceProposalAction<PoolType>>(
            account,
            GovernanceProposalAction { period_release_amount },
            exec_delay,
        );
    }

    /// Perform propose after propose has completed
    public fun execute_proposal<PoolType: copy + drop + store,
                                TokenT: copy + drop + store>(
        proposer_address: address,
        proposal_id: u64
    ) acquires GovernanceCapability {
        let GovernanceProposalAction<PoolType> { period_release_amount } = Dao::extract_proposal_action<
            TokenT,
            GovernanceProposalAction<PoolType>,
        >(proposer_address, proposal_id);

        let cap = borrow_global<GovernanceCapability<PoolType, TokenT>>(Token::token_address<TokenT>());
        Governance::modify_parameter<PoolType, TokenT>(&cap.cap, period_release_amount);
    }
}
}