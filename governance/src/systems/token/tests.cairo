use dojo::world::IWorldDispatcherTrait;
use governance::utils::testing;
use governance::models::token::{
    Metadata, TotalSupply, Allowances, Balances, Delegates, Checkpoints, NumCheckpoints
};
use governance::systems::token::interface::IGovernanceTokenDispatcherTrait;
use starknet::testing::set_contract_address;

#[test]
fn test_initialize_token() {
    let (systems, world) = testing::setup();

    let metadata = get!(world, systems.token.contract_address, Metadata);
    assert!(metadata.name == 'Gov Token', "Name is incorrect");
    assert!(metadata.symbol == 'GOV', "Symbol is incorrect");
    assert!(metadata.decimals == 18, "Decimals is incorrect");

    let total_supply = get!(world, systems.token.contract_address, TotalSupply).amount;
    assert!(total_supply == 100_000_000 * testing::E18, "Total supply is incorrect");

    let governor_balance = get!(world, testing::GOVERNOR(), Balances).amount;
    assert!(governor_balance == 100_000_000 * testing::E18, "Governor balance is incorrect");
}

#[test]
fn test_transfer_token() {
    let (systems, world) = testing::setup();

    let amount = 1_000 * testing::E18;
    let recipient = testing::ACCOUNT_1();

    let governor_balance = get!(world, testing::GOVERNOR(), Balances).amount;
    let recipient_balance = get!(world, recipient, Balances).amount;
    assert!(recipient_balance == 0, "Recipient balance is incorrect");

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(recipient, amount);

    let governor_balance_after = get!(world, testing::GOVERNOR(), Balances).amount;
    let recipient_balance_after = get!(world, recipient, Balances).amount;

    assert!(governor_balance_after == governor_balance - amount, "Governor balance is incorrect");
    assert!(
        recipient_balance_after == recipient_balance + amount, "Recipient balance is incorrect"
    );
}

#[test]
#[should_panic(expected: ("Governance Token: insufficient balance", 'ENTRYPOINT_FAILED'))]
fn test_transfer_token_fails_insufficient_balance() {
    let (systems, _world) = testing::setup();

    let amount = testing::INITIAL_SUPPLY + 1;
    let recipient = testing::ACCOUNT_1();

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(recipient, amount);
}

#[test]
fn test_approve_token() {
    let (systems, world) = testing::setup();

    let amount = 1_000 * testing::E18;
    let recipient = testing::ACCOUNT_1();

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(recipient, amount);

    set_contract_address(testing::ACCOUNT_1());
    systems.token.approve(testing::GOVERNOR(), amount);

    let allowance = get!(world, (testing::ACCOUNT_1(), testing::GOVERNOR()), Allowances).amount;
    assert!(allowance == amount, "Allowance is incorrect");
}

#[test]
fn test_transfer_from_token() {
    let (systems, world) = testing::setup();

    let amount = 1_000 * testing::E18;
    let recipient = testing::ACCOUNT_1();

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(recipient, amount);

    set_contract_address(testing::ACCOUNT_1());
    systems.token.approve(testing::ACCOUNT_2(), amount);

    set_contract_address(testing::ACCOUNT_2());
    systems.token.transfer_from(testing::ACCOUNT_1(), testing::ACCOUNT_3(), amount);
    let recipient_balance = get!(world, testing::ACCOUNT_3(), Balances).amount;
    assert!(recipient_balance == amount, "Recipient balance is incorrect");
}

#[test]
#[should_panic(
    expected: ("Governance Token: transfer amount exceeds spender allowance", 'ENTRYPOINT_FAILED')
)]
fn test_transfer_from_fails_allowance_exceeded() {
    let (systems, _world) = testing::setup();

    let amount = 1_000 * testing::E18;
    let recipient = testing::ACCOUNT_1();

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(recipient, amount);

    set_contract_address(testing::ACCOUNT_1());
    systems.token.approve(testing::ACCOUNT_2(), amount);

    set_contract_address(testing::ACCOUNT_2());
    systems.token.transfer_from(testing::ACCOUNT_1(), testing::ACCOUNT_3(), amount + 1);
}

#[test]
fn test_delegate_token() {
    let (systems, world) = testing::setup();

    let delegate = testing::ACCOUNT_1();

    set_contract_address(testing::GOVERNOR());
    systems.token.delegate(delegate);

    let delegatee = get!(world, testing::GOVERNOR(), Delegates).address;
    assert!(delegatee == delegate, "Delegatee is incorrect");
}

// #[test]
// fn test_change_delegate_token() {
//     let (systems, world) = testing::setup();

//     let delegator = testing::ACCOUNT_1();
//     let delegate_before = testing::ACCOUNT_2();
//     let delegate_after = testing::ACCOUNT_3();

//     set_contract_address(testing::GOVERNOR());
//     systems.token.transfer(delegator, 100 * testing::E18);

//     set_contract_address(delegator);
//     systems.token.delegate(delegate_before);
//     systems.token.delegate(delegate_after);

//     let delegatee = get!(world, testing::ACCOUNT_1(), Delegates).delegatee;
//     assert!(delegatee == delegate_after, "Delegatee is incorrect");
// }

#[test]
fn test_get_current_votes() {
    let (systems, world) = testing::setup();

    let delegate = testing::ACCOUNT_2();

    set_contract_address(testing::GOVERNOR());
    systems.token.transfer(testing::ACCOUNT_1(), 100 * testing::E18);
    let balance = get!(world, testing::ACCOUNT_1(), Balances).amount;
    println!("Balance: {}", balance);
// set_contract_address(testing::ACCOUNT_1());
// systems.token.delegate(testing::ACCOUNT_1());
// let current_votes = systems.token.get_current_votes(testing::ACCOUNT_1());
// println!("Current votes before delegation: {}", current_votes);
// systems.token.delegate(delegate);
// let current_votes = systems.token.get_current_votes(testing::ACCOUNT_1());
// println!("Current votes after: {}", current_votes);
// assert!(current_votes == 100 * testing::E18, "Current votes is incorrect");
}
