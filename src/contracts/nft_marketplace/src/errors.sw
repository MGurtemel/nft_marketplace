library errors;

pub enum Error {
    ZeroAddress: (),
    NotRegistered: (),
    AlreadyRegistered: (),
    ZeroAmount: (),
    NotSetApprovalForAll: (),
    NotListed: (),
    AlreadyListed: (),
    InvalidRange: (),
    CallerNotOwner: (),
    WrongCoin: (),
    WrongCoinAmount: (),
}
