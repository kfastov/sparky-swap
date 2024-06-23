use contracts::VaultRelayer::{IVaultRelayerDispatcher, IVaultRelayerDispatcherTrait};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    // TODO: correct calldata for the constructor
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_relayer_transfer_from() {
    let contract_address = deploy_contract("VaultRelayer");

    let dispatcher = IVaultRelayerDispatcher { contract_address };

    // TODO: test transfer_from
}
