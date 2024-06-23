use starknet::ContractAddress;

#[starknet::interface]
pub trait IVaultRelayer<TContractState> {
    fn transfer_from(self: @TContractState, token: ContractAddress, from: ContractAddress, amount: u256, to: ContractAddress);
    fn set_settlement_address(ref self: TContractState, new_settlement_address: ContractAddress);
}

#[starknet::contract]
mod VaultRelayer {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::{get_caller_address, get_contract_address};
    use core::num::traits::Zero;
    use super::{ContractAddress, IVaultRelayer};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        SettlementAddressChanged: SettlementAddressChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct SettlementAddressChanged {
        #[key]
        old_settlement_address: ContractAddress,
        #[key]
        new_settlement_address: ContractAddress,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        settlement_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, settlement_address: ContractAddress) {
        assert!(settlement_address != Zero::zero(), "settlement_address is not set");
        self.settlement_address.write(settlement_address);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl VaultRelayerImpl of IVaultRelayer<ContractState> {
        fn transfer_from(self: @ContractState, token: ContractAddress, from: ContractAddress, amount: u256, to: ContractAddress) {
            let settlement_address = self.settlement_address.read();
            // reject if settlement address not set
            assert!(settlement_address != Zero::zero(), "settlement_address is not set");
            // only allow transfers initiated from the settlement contract
            assert!(from == settlement_address, "transfer_from: only allowed to transfer from settlement address");
            let dispatcher = IERC20CamelDispatcher { contract_address: token };
            dispatcher.transferFrom(from, to, amount);
        }
        fn set_settlement_address(ref self: ContractState, new_settlement_address: ContractAddress) {
            self.ownable.assert_only_owner();
            assert!(new_settlement_address != Zero::zero(), "new_settlement_address is not set");
            self.settlement_address.write(new_settlement_address);
        }
    }
}
