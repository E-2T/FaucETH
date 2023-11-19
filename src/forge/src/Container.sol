// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Container {
    modifier eventExists(string memory code) {
        require(_events[code].owner != address(0), "No event found for the provided code");
        _;
    }
    modifier onlyOwner(string memory code) {
        require(_events[code].owner == msg.sender, "You don't have the permission to perform that");
        _;
    }
    struct Redeem {
        uint time;
        uint total;
    }
    struct EventData {
        uint balance;
        address owner;
        address[] whitelist;
        mapping(address => Redeem) lastWithdraws;
        uint withdrawLimit;
        uint withdrawInterval;
        bool isPublic;
    }
    event EventUpdated(uint balance, string name, address owner, address[] whitelist, uint withdrawLimit, uint withdrawInterval);

    mapping(string => EventData) private _events;
    string[] private _keys;
    uint private _defaultWithdrawLimit;
    uint private _defaultInterval;

    constructor(uint defaultWithdrawLimit, uint defaultInterval) {
        _defaultWithdrawLimit = defaultWithdrawLimit > 0 ? defaultWithdrawLimit : 5 * 10e17;
        _defaultInterval = defaultInterval > 0 ? defaultInterval : 60 * 60;
    }

    // Create a new event
    function createEvent(string memory name, address[] memory whitelist, uint withdrawLimit, uint withdrawInterval) public{
        string memory code = _getCodeFromName(name);
        require(_events[code].owner == address(0), "Event with this name already exists");
        _events[code].whitelist = whitelist;
        _events[code].owner = msg.sender;
        _events[code].withdrawLimit = withdrawLimit > 0 ? withdrawLimit : _defaultWithdrawLimit;
        _events[code].withdrawInterval = withdrawInterval > 0 ? withdrawInterval : _defaultInterval;
        _keys.push(code);
        emit EventUpdated(0, code, msg.sender, whitelist, withdrawLimit, withdrawInterval);
    }
    // Donate token to an event
    function donateTokens(string memory code) public payable eventExists(code){
        _events[code].balance += msg.value;
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    // Withdraw tokens from specific event
    function withdrawTokens(string memory code, uint amount) public eventExists(code){
        if(_events[code].owner != msg.sender){
            require(_events[code].isPublic, "You don't have the permission to perform that");
            require(_arrayAddrIndexOf(_events[code].whitelist, msg.sender) > 0, "You don't have the permission to perform that");
        }
        require(_events[code].balance - amount >= 0, "Insufficent event balance. Try specifying a lower amount");
        if(_events[code].lastWithdraws[msg.sender].time + _events[code].withdrawInterval < block.timestamp){
            _events[code].lastWithdraws[msg.sender].time = 0;
            _events[code].lastWithdraws[msg.sender].total = 0;
        }
        require(_events[code].lastWithdraws[msg.sender].total + amount <= _events[code].withdrawLimit, "Withdraw limit reached for the current time window");
        if(_events[code].lastWithdraws[msg.sender].time == 0){
            _events[code].lastWithdraws[msg.sender].time = block.timestamp;
        }
        _events[code].lastWithdraws[msg.sender].total += amount;
        _events[code].balance -= amount;
        payable(msg.sender).transfer(amount); //payable(msg.sender).call{value: amount }("");
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    // Setters & Getters
    function updateWhitelist(string memory code, address user, bool value) public eventExists(code) onlyOwner(code){
        uint index = _arrayAddrIndexOf(_events[code].whitelist, user);
        if(index > 0){
            _events[code].whitelist[index - 1] = !value ? address(0) : user;
        }else if(value){
            _events[code].whitelist.push(user);
        }
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    function updatePublic(string memory code, bool isPublic) public eventExists(code) onlyOwner(code){
        _events[code].isPublic = isPublic;
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    function updateWithdrawInterval(string memory code, uint withdrawInterval) public onlyOwner(code){
        _events[code].withdrawInterval = withdrawInterval;
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    function updateWithdrawLimit(string memory code, uint withdrawLimit) public onlyOwner(code){
        _events[code].withdrawLimit = withdrawLimit;
        emit EventUpdated(_events[code].balance, code, _events[code].owner, _events[code].whitelist, _events[code].withdrawLimit, _events[code].withdrawInterval);
    }
    function isUserOwner(string memory code, address user) public view returns(bool){
        return _events[code].owner == user;
    }
    function isUserWhitelisted(string memory code, address user) public view returns(bool){
        return _arrayAddrIndexOf(_events[code].whitelist, user) > 0;
    }
    function isEventPublic(string memory code) public view returns(bool){
        return _events[code].isPublic;
    }
    function getEvetBalance(string memory code) public view returns(uint){
        return _events[code].balance;
    }
    function getEventWithdrawLimit(string memory code) public view returns(uint){
        return _events[code].withdrawLimit;
    }
    function getWithdrawInterval(string memory code) public view returns(uint){
        return _events[code].withdrawInterval;
    }
    function getUserEvents(address user) public view returns (string[] memory) {
        string[] memory arr = new string[](_keys.length);
        uint length = _keys.length;
        for(uint i = 0; i < length;){
            if((_events[_keys[i]].isPublic && _arrayAddrIndexOf(_events[_keys[i]].whitelist, user) > 0) || _events[_keys[i]].owner == user){
                arr[i] = _keys[i];
            }
            unchecked{
                i++;
            }
        }
        return arr;
    }
    function getUserRedeem(string memory code, address user) public view onlyOwner(code) returns (Redeem memory){
        return _events[code].lastWithdraws[user];
    }
    // Utils
    function _getCodeFromName(string memory name) private pure returns(string memory) {
        return name;
    }
    function _stringEquals(string memory s1, string memory s2) private pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
    // 0 = not found; 1 = first index
    function _arrayAddrIndexOf(address[] memory arr, address str)private pure returns(uint){
        uint length = arr.length;
        for(uint i = 0; i < length; i++){
            if(arr[i] == str){
                return i + 1;
            }
        }
        return 0;
    }
}