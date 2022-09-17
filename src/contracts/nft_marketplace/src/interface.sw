library interface;

dep data_structures;

use data_structures::{Collection, Item};
use std::{address::Address,contract_id::ContractId};

abi NFTMarketplace {
    #[storage(read, write)]
    fn register_collection(contract_id: ContractId);

    #[storage(read)]
    fn get_collection(contract_id: ContractId) -> Collection;

    #[storage(read)]
    fn get_collection_by_id(collection_id: u64) -> Collection;

    #[storage(read)]
    fn total_registered_collections() -> u64;

    #[storage(read, write)]
    fn list_nft(contract_id: ContractId, token_id: u64, price: u64);

    #[storage(read)]
    fn get_listed_nft(contract_id: ContractId, item_id: u64) -> Item;

    #[storage(read, write)]
    fn purchase_nft(contract_id: ContractId, token_id: u64);
}
