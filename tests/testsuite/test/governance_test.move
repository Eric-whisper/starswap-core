//! account: alice, 100000000000000000 0x1::STC::STC
//! account: joe
//! account: admin, 0x81144d60492982a45ba93fba47cae988, 10000000000000 0x1::STC::STC
//! account: liquidier, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: alice
address alice = {{alice}};
module alice::TokenMock {
    use 0x1::Token;
    use 0x1::Governance;
    use 0x1::Signer;

    struct Usdx has copy, drop, store {}

    struct GovModfiyParamCapability<PoolType, AssetT> has key, store {
        cap: Governance::ParameterModifyCapability<PoolType, AssetT>,
    }

    struct PoolType_A has copy, drop, store {}

    struct AssetType_A has copy, drop, store { 
        value: u128 
    }

    public fun initialize(account: &signer, treasury: Token::Token<Usdx>) {
        Governance::initialize<PoolType_A, Usdx>(account, treasury);
        let asset_cap = Governance::initialize_asset<PoolType_A, AssetType_A>(account, 100, 0);
        move_to(account, GovModfiyParamCapability<PoolType_A, AssetType_A> {
            cap: asset_cap,
        });
    }

    /// Claim an asset in to pool
    public fun claim(account: &signer) {
        Governance::claim<PoolType_A, Usdx, AssetType_A>(
            account, @alice, AssetType_A { value: 0 });
    }

    public fun stake(account: &signer, value: u128) {
        let asset_wrapper = Governance::borrow_asset<PoolType_A, AssetType_A>(Signer::address_of(account));
        let (asset, _) = Governance::borrow<PoolType_A, AssetType_A>(&mut asset_wrapper);
        asset.value = asset.value + value;
        Governance::modify<PoolType_A, AssetType_A>(&mut asset_wrapper, asset.value);
        Governance::stake<PoolType_A, Usdx, AssetType_A>(account, @alice, asset_wrapper);
    }

    public fun harvest(account: &signer) : Token::Token<Usdx> {
        Governance::harvest<PoolType_A, Usdx, AssetType_A>(account, @alice, 0)
    }

    public fun query_gov_token_amount(account: &signer) : u128 {
        Governance::query_gov_token_amount<PoolType_A, Usdx, AssetType_A>(account, @alice)
    }
}
// check: EXECUTED

//! block-prologue
//! author: genesis
//! block-number: 1
//! block-time: 10000000

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Math;
    use alice::TokenMock::{Usdx};

    fun init(account: signer) {
        let precision: u8 = 9; //STC precision is also 9.
        let scaling_factor = Math::pow(10, (precision as u64));
        let usdx_amount: u128 = 100000000 * scaling_factor;

        // Resister and mint Usdx
        Token::register_token<Usdx>(&account, precision);
        Account::do_accept_token<Usdx>(&account);
        let usdx_token = Token::mint<Usdx>(&account, usdx_amount);
        Account::deposit_to_self(&account, usdx_token);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x1::Account;
    //use 0x1::Token;
    use 0x1::Math;
    use alice::TokenMock;

    fun init(account: signer) {
        let precision: u8 = 9; //STC precision is also 9.
        let scaling_factor = Math::pow(10, (precision as u64));
        let usdx_amount: u128 = 100 * scaling_factor;

        let tresury = Account::withdraw(&account, usdx_amount);
        TokenMock::initialize(&account, tresury);
    }
}
// check: EXECUTED

//! block-prologue
//! author: genesis
//! block-number: 2
//! block-time: 100000100

//! new-transaction
//! sender: joe
address alice = {{alice}};
address joe = {{joe}};
script {
    use alice::TokenMock;

    fun init(account: signer) {
        TokenMock::claim(&account);
        TokenMock::stake(&account, 1000);
    }
}
// check: EXECUTED

//! block-prologue
//! author: genesis
//! block-number: 3
//! block-time: 100000100

//! new-transaction
//! sender: joe
//address joe = {{joe}};
address alice = {{alice}};
script {
   use alice::TokenMock;

   fun init(account: signer) {
       let amount = TokenMock::query_gov_token_amount(&account);
       assert(amount > 0, 1001);
   }
}
// check: EXECUTED


// //! new-transaction
// //! sender: joe
// //address joe = {{joe}};
// address alice = {{alice}};
// script {
//     use alice::TokenMock;
//     use 0x1::Account;
//     use 0x1::Token;
//     use 0x1::Signer;

//     fun init(account: signer) {
//         let token = TokenMock::harvest(&account);
//         Account::do_accept_token<TokenMock::Usdx>(&account);

//         let token_balance = Token::value<TokenMock::Usdx>(&token);
//         assert(token_balance == 10000, 10000);
//         Account::deposit<TokenMock::Usdx>(Signer::address_of(&account), token);
//     }
// }