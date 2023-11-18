// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Container {
    struct Redeem {
        uint time;
        uint total;
    }
    struct EventData {
        uint balance;
        address owner;
        mapping(address => bool) whitelist;
        mapping(address => Redeem) lastWithdraws;
        uint withdrawLimit;
        uint withdrawInterval;
        bool isPublic;
    }
    event EventCreated(string name, address owner, address[] whitelist, uint withdrawLimit);
    event EventVisibilityChanged(string name, bool value);

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
        for(uint i = 0; i < whitelist.length; i++){
            _events[code].whitelist[whitelist[i]] = true;
        }
        _events[code].owner = msg.sender;
        _events[code].withdrawLimit = withdrawLimit > 0 ? withdrawLimit : _defaultWithdrawLimit;
        _events[code].withdrawInterval = withdrawInterval > 0 ? withdrawInterval : _defaultInterval;
        _keys.push(code);
        emit EventCreated(code, msg.sender, whitelist, withdrawLimit);
    }
    // Donate token to an event
    function donateTokens(string memory code) public payable{
        require(_events[code].owner != address(0));
        _events[code].balance += msg.value;
    }
    // Withdraw tokens from specific event
    function withdrawTokens(string memory code, uint amount) public{
        require(_events[code].owner != address(0));
        require(_events[code].isPublic || _events[code].owner == msg.sender);
        require(_events[code].whitelist[msg.sender] || _events[code].owner == msg.sender);
        require(_events[code].balance - amount >= 0);
        require(_events[code].lastWithdraws[msg.sender].total + amount <= _events[code].withdrawLimit);
        if(_events[code].lastWithdraws[msg.sender].time > block.timestamp + _events[code].withdrawInterval){
            _events[code].lastWithdraws[msg.sender].time = block.timestamp;
            _events[code].lastWithdraws[msg.sender].total = amount;
        }else{
            _events[code].lastWithdraws[msg.sender].total += amount;
        }
        _events[code].balance -= amount;
        payable(msg.sender).call{value: amount }("");
    }
    // Setters & Getters
    function updateWhitelist(string memory code, address user, bool value) public{
        require(_events[code].owner != address(0));
        require(msg.sender == _events[code].owner);
        _events[code].whitelist[user] = value;
    }
    function updatePublic(string memory code, bool isPublic) public{
        require(_events[code].owner != address(0));
        require(msg.sender == _events[code].owner);
        _events[code].isPublic = isPublic;
        emit EventVisibilityChanged(code, isPublic);
    }
    function updateWithdrawLimit(string memory code, uint withdrawLimit) public{
        require(_events[code].owner != address(0));
        require(msg.sender == _events[code].owner);
        _events[code].withdrawLimit = withdrawLimit;
    }
    function isUserOwner(string memory code, address user) public view returns(bool){
        return _events[code].owner == user;
    }
    function isUserWhitelisted(string memory code, address user) public view returns(bool){
        return _events[code].whitelist[user];
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
    function getUserEvents() public view returns (string[] memory) {
        string[] memory arr = new string[](_keys.length);
        for(uint i = 0; i < _keys.length; i++){
            if((_events[_keys[i]].isPublic && _events[_keys[i]].whitelist[msg.sender]) || _events[_keys[i]].owner == msg.sender){
                arr[i] = _keys[i];
            }
        }
        return arr;
    }
    function getUserEvents(address user) public view returns (string[] memory) {
        string[] memory arr = new string[](_keys.length);
        for(uint i = 0; i < _keys.length; i++){
            if((_events[_keys[i]].isPublic && _events[_keys[i]].whitelist[user]) || _events[_keys[i]].owner == user){
                arr[i] = _keys[i];
            }
        }
        return arr;
    }
    function getUserRedeem(string memory code, address user) public view returns (Redeem memory){
        require(msg.sender == _events[code].owner);
        return _events[code].lastWithdraws[user];
    }
    // Utils
    function _getCodeFromName(string memory name) private pure returns(string memory) {
        return name;
    }
    function _stringEquals(string memory s1, string memory s2) private pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}