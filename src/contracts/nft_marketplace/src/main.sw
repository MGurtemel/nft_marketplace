contract;

dep utils;
dep errors;
dep data_structures;
dep interface;
dep events;
dep constants;

use interface::NFTMarketplace;
use events::*;
use constants::*;
use errors::Error;
use core::ops::*;
use nft_abi::NFT;
use utils::get_msg_sender_address_or_panic;
use data_structures::{Collection, Item};
use std::{
    chain::auth::msg_sender,
    address::Address,
    logging::log,
    option::Option,
    result::Result,
    revert::require,
    storage::StorageMap,
    context::{*, call_frames::*},
    contract_id::ContractId,
    token::*,
};

storage {
    collection: StorageMap<ContractId, Collection> = StorageMap {},
    collection_by_id: StorageMap<u64, Collection> = StorageMap {},
    is_registered: StorageMap<ContractId, bool> = StorageMap {},
    collection_counter: u64 = 0,
    listed_nft: StorageMap<(ContractId, u64), Item> = StorageMap {},
    is_listed: StorageMap<(ContractId, u64), bool> = StorageMap {},
}

#[storage(read, write)]
fn register(contract_Id: ContractId, creator: Address) {
    storage.collection_counter += 1;
    let current_counter = storage.collection_counter + 1;
    storage.is_registered.insert(contract_Id, true);
    storage.collection.insert(contract_Id, ~Collection::new(contract_Id, current_counter, creator));
    storage.collection_by_id.insert(current_counter, ~Collection::new(contract_Id, current_counter, creator));

    log(RegisterEvent {
        contract_Id,
        creator,
    });
}

#[storage(read)]
fn get_nft(contract_Id: ContractId, item_id: u64) -> Item {
    require(contract_Id.into() != ZERO_B256, Error::ZeroAddress);

    let collection = storage.collection.get(contract_Id);
    let total_items_in_collection = collection.num_listed_nfts;
    require(0 < item_id && item_id <= total_items_in_collection, Error::InvalidRange);

    storage.listed_nft.get((
        contract_Id,
        item_id,
    ))
}

impl NFTMarketplace for Contract {
    #[storage(read, write)]
    fn register_collection(contract_Id: ContractId) {
        require(contract_Id.into() != ZERO_B256, Error::ZeroAddress);
        require(!storage.is_registered.get(contract_Id), Error::AlreadyRegistered);

        let sender = get_msg_sender_address_or_panic();
        register(contract_Id, sender);
    }

    #[storage(read)]
    fn get_collection(contract_Id: ContractId) -> Collection {
        require(contract_Id.into() != ZERO_B256, Error::ZeroAddress);
        require(storage.is_registered.get(contract_Id), Error::NotRegistered);

        storage.collection.get(contract_Id)
    }

    #[storage(read)]
    fn get_collection_by_id(collection_id: u64) -> Collection {
        //require(0 < collection_id && collection_id <= storage.collection_counter, Error::InvalidRange);

        storage.collection_by_id.get(collection_id)
    }

    #[storage(read)]
    fn total_registered_collections() -> u64 {
        storage.collection_counter
    }

    #[storage(read, write)]
    fn list_nft(contract_Id: ContractId, token_id: u64, price: u64) {
        require(contract_Id.into() != ZERO_B256, Error::ZeroAddress);
        require(price > 0, Error::ZeroAmount);
        require(!storage.is_listed.get((contract_Id, token_id)), Error::AlreadyListed);

        let owner = get_msg_sender_address_or_panic();

        if(!storage.is_registered.get(contract_Id)) {
            register(contract_Id, owner);
        }

        let nft = abi(NFT, contract_Id.into());
        let this_contract_id = contract_id();
        let this_contract = Address { value: this_contract_id.into() };
        require(nft.owner_of(token_id) == owner, Error::CallerNotOwner);
        require(nft.is_approved_for_all(this_contract, owner), Error::NotSetApprovalForAll);

        let mut collection = storage.collection.get(contract_Id);
        collection.num_listed_nfts += 1;

        storage.is_listed.insert((contract_Id, token_id), true);
        storage.listed_nft.insert((contract_Id, collection.num_listed_nfts), ~Item::new(contract_Id, token_id, owner, price));

        log(ListEvent {
            contract_Id,
            token_id,
            owner,
            price,
        });
    }

    #[storage(read)]
    fn get_listed_nft(contract_Id: ContractId, item_id: u64) -> Item {
        let item = get_nft(contract_Id, item_id);
        item
    }

    #[storage(read, write)]
    fn purchase_nft(contract_Id: ContractId, item_id: u64) {
        require(msg_asset_id() == BASE_TOKEN, Error::WrongCoin);

        let item = get_nft(contract_Id, item_id);
        let item_price = item.price;
        require(msg_amount() == item_price, Error::WrongCoinAmount);

        let nft_address = item.contract_id.into();
        let nft = abi(NFT, nft_address);
        let seller = item.owner;
        let token_id = item.token_id;

        let mut collection = storage.collection.get(contract_Id);
        collection.num_listed_nfts -= 1;

        storage.is_listed.insert((contract_Id, token_id), false);
        storage.listed_nft.insert((contract_Id, item_id), ~Item::new(ZERO_CONTRACT_ID, 0, ZERO_ADDRESS, 0));

        let buyer = get_msg_sender_address_or_panic();
        nft.transfer_from(seller, buyer, token_id);

        let fee = msg_amount().divide(100);
        let transfer_amount = msg_amount().subtract(fee);
        transfer_to_output(msg_amount(), BASE_TOKEN, seller);

        log(PurchaseEvent {
            contract_Id,
            token_id,
            seller,
            buyer,
        });
    }
}
