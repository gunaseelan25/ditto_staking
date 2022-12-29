module kana_staking::kana_staking {
    use std::signer;
    use ditto_staking::ditto_staking;
    use ditto_staking::staked_coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;


    const MAX_FEE: u64 = 500;
    const E_MORETHAN_MAX_FEE: u64 = 5;
    const E_NOT_ADMIN: u64 = 4;
    
     struct Platform has key { receiver: address, fee:u64}


    public entry fun invoke_ditto_stake_aptos(user: &signer, amount: u64) {
        ditto_staking::stake_aptos(user, amount);
    }

    public entry fun invoke_ditto_instant_unstake(user: &signer, amount: u64) {
        ditto_staking::instant_unstake(user, amount);
    }

    public entry fun invoke_ditto_delayed_unstake(user: &signer, amount: u64) {
        ditto_staking::delayed_unstake(user, amount);
    }

    public entry fun invoke_ditto_claim_aptos(user: &signer) {
        ditto_staking::claim_aptos(user);
    }

    public entry fun invoke_ditto_exchange_aptos(user: &signer, amount: u64) acquires Platform {
        let user_addr = signer::address_of(user);

        if (!coin::is_account_registered<staked_coin::StakedAptos>(user_addr)) {
            staked_coin::register(user);
        };
        let platform = borrow_global<Platform>(@kana_staking);
        let platform_fee = cal_fee(amount, platform.fee);
        let coins = coin::withdraw<AptosCoin>(user, amount);
        let platform_fee_coin = coin::extract(&mut coins, platform_fee);
        coin::deposit(platform.receiver, platform_fee_coin);
        let staked_coins = ditto_staking::exchange_aptos(coins, user_addr);
        coin::deposit(user_addr, staked_coins);
    }

    public entry fun invoke_ditto_exchange_staptos(user: &signer, amount: u64) {
        let user_addr = signer::address_of(user);

        let staked_coin = coin::withdraw<staked_coin::StakedAptos>(user, amount);
        let unstaked_aptos = ditto_staking::exchange_staptos(staked_coin, user_addr);
        coin::deposit(user_addr, unstaked_aptos);
    }

    public entry fun invoke_ditto_delayed_exchange_staptos(user: &signer, amount: u64) {
        let staked_coin = coin::withdraw<staked_coin::StakedAptos>(user, amount);
        let user_addr = signer::address_of(user);
        ditto_staking::delayed_exchange_staptos(staked_coin, user_addr);
    }

    public entry fun invoke_ditto_claim_queued_aptos(user: &signer) {
        coin::deposit(signer::address_of(user), ditto_staking::claim_queued_aptos(user));
    }
    public entry fun set_platform_profile(account: &signer, rec:address, fee:u64) {
         assert!(fee <= MAX_FEE, E_MORETHAN_MAX_FEE);
        let admin_addr = signer::address_of(account);
        assert!(admin_addr == @kana_staking, E_NOT_ADMIN);

        if(!exists<Platform>(admin_addr)){
            let platform_profile = Platform {receiver:rec, fee:fee};
            move_to(account, platform_profile)
        } 
    }

    public entry fun update_platform_fee_amount(account: &signer, fee:u64) acquires Platform{
        assert!(fee <= MAX_FEE, E_MORETHAN_MAX_FEE);
        let admin_addr = signer::address_of(account);
        assert!(admin_addr == @kana_staking, E_NOT_ADMIN);
        let platform_profile = borrow_global_mut<Platform>(admin_addr);
        platform_profile.fee = fee;
    }

    public entry fun update_platform_fee_receiver(account: &signer, rec:address) acquires Platform{
        let admin_addr = signer::address_of(account);
        assert!(admin_addr == @kana_staking, E_NOT_ADMIN);
        let platform_profile = borrow_global_mut<Platform>(admin_addr);
        platform_profile.receiver = rec;
    }
     fun cal_fee(in_amount: u64, fee: u64): u64 {
        let fee = (in_amount * fee) / 10000;
        (fee)
    }
}