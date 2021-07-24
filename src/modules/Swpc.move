address 0xbd7e8be8fae9f60f2f5136433e36a091 {
/// USDx is a test token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module Swpc {

    // use 0x1::Token;
    use 0x1::Account;

    // Dao config
    use 0x1::Token;
    use 0x1::Dao;
    use 0x1::ModifyDaoConfigProposal;
    use 0x1::UpgradeModuleDaoProposal;
    use 0x1::PackageTxnManager;
    use 0x1::OnChainConfigDao;

    use 0xbd7e8be8fae9f60f2f5136433e36a091::TokenSwapConfig;
//    use 0x1::VMConfig;
//    use 0x1::ConsensusConfig;
//    use 0x1::RewardConfig;
//    use 0x1::TransactionTimeoutConfig;
//    use 0x1::TransactionPublishOption;
    use 0x1::Option;
    use 0x1::Config;
    use 0x1::Version;
    use 0x1::Signer;

    /// USDx token marker.
    struct Swpc has copy, drop, store {}

    /// precision of USDx token.
    const PRECISION: u8 = 9;

    /// USDx initialization.
    public ( script ) fun init(account: signer) {
        Token::register_token<Swpc>(&account, PRECISION);
        Account::do_accept_token<Swpc>(&account);

        // Configable
        if (!Config::config_exist_by_address<Version::Version>(Signer::address_of(&account))) {
            Config::publish_new_config<Version::Version>(&account, Version::new_version(1));
        };

        // Update upgrade strategy two phase
        PackageTxnManager::update_module_upgrade_strategy(
            &account,
            PackageTxnManager::get_strategy_two_phase(),
            Option::some(3600000u64),
        );

        Dao::plugin<Swpc>(
            &account,
            3600000,
            3600000,
            50,
            3600000,
        );
        let upgrade_plan_cap = PackageTxnManager::extract_submit_upgrade_plan_cap(&account);
        UpgradeModuleDaoProposal::plugin<Swpc>(
            &account,
            upgrade_plan_cap,
        );

        ModifyDaoConfigProposal::plugin<Swpc>(&account);

        // Initialize configration value to 0
        TokenSwapConfig::initialize(&account, 0u128);

        // the following configurations are gov-ed by Dao.
        OnChainConfigDao::plugin<Swpc, TokenSwapConfig::TokenSwapConfig>(&account);
    }

    public ( script ) fun mint(account: signer, amount: u128) {
        let token = Token::mint<Swpc>(&account, amount);
        Account::deposit_to_self<Swpc>(&account, token);
    }

    /// Returns true if `TokenType` is `USDx::USDx`
    public fun is_usdx<TokenType: store>(): bool {
        Token::is_same_token<Swpc, TokenType>()
    }

    spec is_usdx {}

    /// Return USDx token address.
    public fun token_address(): address {
        Token::token_address<Swpc>()
    }

    spec token_address {}
}
}