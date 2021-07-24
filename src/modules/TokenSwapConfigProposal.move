// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0xbd7e8be8fae9f60f2f5136433e36a091 {
module TokenSwapConfigProposal {
    use 0x1::Signer;
    use 0x1::OnChainConfigDao;
    use 0x1::Token;
    use 0xbd7e8be8fae9f60f2f5136433e36a091::Swpc;
    use 0xbd7e8be8fae9f60f2f5136433e36a091::TokenSwapConfig;

    ///
    /// propose config change to dao module
    ///
    public ( script ) fun propose_update_swap_config(account: signer,
                                                     config_value: u128,
                                                     exec_delay: u64) {
        let swap_conf = TokenSwapConfig::make_new_config(config_value);
        OnChainConfigDao::propose_update<Swpc::Swpc, TokenSwapConfig::TokenSwapConfig>(
            &account, swap_conf, exec_delay);
    }


    ///
    /// execute on chain config proposal
    //
    public ( script ) fun execute_on_chain_config_proposal(
        account: signer, proposal_id: u64) {
        OnChainConfigDao::execute<Swpc::Swpc, TokenSwapConfig::TokenSwapConfig>(
            Signer::address_of(&account), proposal_id);
    }

    ///
    /// query swap global config
    //
    public ( script ) fun query_swap_config() : u128 {
        let publisher_address = Token::token_address<Swpc::Swpc>();
        TokenSwapConfig::token_swap_config(publisher_address)
    }
}
}