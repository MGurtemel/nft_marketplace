library events;

use std::{
    address::Address,
    contract_id::ContractId,
};

pub struct RegisterEvent{
    contract_Id: ContractId,
    creator: Address
}

pub struct ListEvent {
    contract_Id: ContractId,
    token_id: u64,
    owner: Address,
    price: u64,
}

pub struct PurchaseEvent {
    contract_Id: ContractId,
    token_id: u64,
    seller: Address,
    buyer: Address,
}
