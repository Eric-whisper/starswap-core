address 0xbd7e8be8fae9f60f2f5136433e36a091 {
/// Bot is a test token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module Bot {
    // use 0x1::Token::{Self, Token};
    // use 0x1::Dao;

    use 0x1::Token;
    use 0x1::Account;
//    use 0x1::Dao;
//    use 0x1::ModifyDaoConfigProposal;
//    use 0x1::UpgradeModuleDaoProposal;
//    use 0x1::PackageTxnManager;
//    use 0x1::OnChainConfigDao;
//    use 0x1::TransactionPublishOption;
//    use 0x1::VMConfig;
//    use 0x1::ConsensusConfig;
//    use 0x1::RewardConfig;
//    use 0x1::TransactionTimeoutConfig;

    /// Bot token marker.
    struct Bot has copy, drop, store { }

    /// precision of Bot token.
    const PRECISION: u8 = 18;

    /// Bot initialization.
    public(script) fun init(account: signer) {
        Token::register_token<Bot>(&account, PRECISION);
        Account::do_accept_token<Bot>(&account);

//        Dao::plugin<Bot>(
//            &account,
//            1, // voting_delay,
//            1000, // voting_period,
//            5, // voting_quorum_rate,
//            1, // min_action_delay,
//        );
//
//        ModifyDaoConfigProposal::plugin<Bot>(&account);
//        let upgrade_plan_cap = PackageTxnManager::extract_submit_upgrade_plan_cap(&account);
//        //assert(Option::is_none<PackageTxnManager::UpgradePlanCapability>(&upgrade_plan_cap), 1000);
//        UpgradeModuleDaoProposal::plugin<Bot>(
//            &account,
//            upgrade_plan_cap,
//        );
//        // the following configurations are gov-ed by Dao.
//        OnChainConfigDao::plugin<Bot, TransactionPublishOption::TransactionPublishOption>(&account);
//        OnChainConfigDao::plugin<Bot, VMConfig::VMConfig>(&account);
//        OnChainConfigDao::plugin<Bot, ConsensusConfig::ConsensusConfig>(&account);
//        OnChainConfigDao::plugin<Bot, RewardConfig::RewardConfig>(&account);
//        OnChainConfigDao::plugin<Bot, TransactionTimeoutConfig::TransactionTimeoutConfig>(&account);
    }

//    public (script) fun plan(account: signer, package_hash: vector<u8>, version:u64, enforced: bool) {
//        PackageTxnManager::submit_upgrade_plan_v2(&account, package_hash, version, enforced);
//    }

    public(script) fun mint(account: signer, amount: u128) {
        let token = Token::mint<Bot>(&account, amount);
        Account::deposit_to_self<Bot>(&account, token)
    }

    /// Returns true if `TokenType` is `Bot::Bot`
    public fun is_bot<TokenType: store>(): bool {
        Token::is_same_token<Bot, TokenType>()
    }

    spec is_bot {
    }

    /// Return Bot token address.
    public fun token_address(): address {
        Token::token_address<Bot>()
    }

    spec token_address {
    }
}
}