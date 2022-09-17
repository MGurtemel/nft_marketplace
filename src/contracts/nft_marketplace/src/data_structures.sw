library data_structures;

use std::{
    address::Address,
    contract_id::ContractId,
};

pub struct Collection {
    contract_id: ContractId,
    collection_id: u64,
    creator: Address,
    floor_price: u64,
    num_listed_nfts: u64,
}

impl Collection {
    fn new(contract_Id: ContractId, collection_id: u64, creator: Address) -> Self {
        Self {
            contract_id: contract_Id,
            creator: creator,
            collection_id: collection_id,
            floor_price: 0,
            num_listed_nfts: 0,
        }
    }
}

pub struct Item {
    contract_id: ContractId,
    token_id: u64,
    owner: Address,
    price: u64,
}

impl Item {
    fn new(contract_Id: ContractId, token_id: u64, owner: Address, price: u64) -> Self {
        Self {
            contract_id: contract_Id,
            token_id: token_id,
            owner: owner,
            price: price,
        }
    }
}
