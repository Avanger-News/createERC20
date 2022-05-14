// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract ERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }

    function totalSupply() public view returns (uint256) { return _totalSupply; }

    function balanceOf(address _owner) public view returns (uint256) { return _balances[_owner]; }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[msg.sender] >= _value, "ERC20: insufficient funds");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "ERC20: approval from zero address");
        require(_value > 0, "ERC20: approval requires a non-zero amount");

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_from != address(0), "ERC20: transfer from zero address");
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[_from] >= _value, "ERC20: insufficient funds");
        require(_allowed[_from][msg.sender] >= _value, "ERC20: insufficient allowed funds");

        _balances[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract AvangerNews is ERC20 {
    address public _minter;
    address public _dev_fee_address;
    uint256 public _maxSupply;
    uint256 public _initialSupply;
    bool public _devFeeEnabled;

    event Minted(address indexed _to, uint256 _value);
    event Burned(address indexed _from, uint256 _value);
    event SwitchedMinter(address indexed _old, address indexed _new);
    event SwitchedDevfee(address indexed _old, address indexed _new);
    event ToggledDevFee(bool _devfeeStatus);

    constructor() {
    
        _name = "AVNGR";
        _symbol = "AVNGR";
        _decimals = 18;
        _maxSupply = 21000000 * (10 ** _decimals);
        _initialSupply = 21000000 * (10 ** _decimals);
        _totalSupply = _initialSupply;
        _devFeeEnabled = false;
        
        _balances[msg.sender] = _initialSupply;
        _minter = msg.sender;
        _dev_fee_address = msg.sender;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

   
    modifier minterOnly() {
        require(msg.sender == _minter, "Account doesn't have minting privileges");
        _;
    }

    function switchMinter(address _newMinter) public minterOnly returns (bool) {
       
        require(_newMinter != address(0), "Transferring ownership to zero account is forbidden");

        _minter = _newMinter;
        emit SwitchedMinter(msg.sender, _minter);
        return true;
    }

    function mint(address _to, uint256 _amount) public minterOnly returns (bool) {
        require(_to != address(0), "Minting to zero account is forbidden");
        require(_amount > 100000, "Minting requires at least 0.0000000000001 AVGNR");
        if (_devFeeEnabled) {
            uint256 _amount_devfee = _amount / 20;  // 5%
            uint256 _totalAmount = _amount_devfee + _amount;
            require(_totalAmount + _totalSupply < _maxSupply, "Minting will result in more than the max supply; denied");
            _totalSupply += _amount_devfee;
            _balances[_dev_fee_address] += _amount_devfee;
            emit Minted(_dev_fee_address, _amount_devfee);
            emit Transfer(address(0), _dev_fee_address, _amount_devfee);
        } else {
            require(_amount + _totalSupply < _maxSupply, "Minting will result in more than max supply; denied");
        }
        
       
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit Minted(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    
    modifier devfeeOnly() {
        require(msg.sender == _dev_fee_address, "Account doesn't have devfee privileges");
        _;
    }

    function switchDevfee(address _new_dev_fee_address) public devfeeOnly returns (bool) {
        require(_new_dev_fee_address != address(0), "Transferring ownership to zero account is forbidden");

        _dev_fee_address = _new_dev_fee_address;
        emit SwitchedDevfee(msg.sender, _dev_fee_address);
        return true;
    }
    
    function toggleDevfee(bool _devfeeStatus) public devfeeOnly returns (bool) {
        _devFeeEnabled = _devfeeStatus;
        emit ToggledDevFee(_devfeeStatus);
        return true;
    }

 
    function burn(uint256 _amount) public returns (bool) {
        require(_amount > 0, "Burning requires a non-zero amount");
        require(_amount <= _balances[msg.sender], "ERC20: insufficient funds");
        
        _balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        _balances[address(0)] += _amount;
        emit Burned(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }
}
