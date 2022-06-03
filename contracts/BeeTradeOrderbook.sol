pragma solidity >=0.5.0;

import './IERC20.sol';

contract BeeTradeOrderbook {

    address public admin; // the admin address
    uint256 public fee; //percentage times (1 ether)
    address public feesAccount; //the account that will receive fees
    address public tradesAccount; // the address that can execute trades
    address AVAX = address(0); // using the zero address to represent avax token

    struct Balance {
        uint256 available;
        uint256 locked;
    }

    mapping (address => mapping (address => Balance)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping(string => bool)) public usersOrders; // mapping of users addresses to ordersID's

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event CreateOrder(
        address indexed account, 
        uint256 amount, 
        string buySell, 
        string date, 
        string orderType, 
        string indexed pair, 
        uint256 price, 
        string indexed orderID
    );
    event CancelOrder(address user, string indexed pair, string indexed orderType, string indexed orderID);
    
    event Trade(
        address indexed maker,
        address indexed taker,
        uint256 amountGet, 
        uint256 amountGive,
        string makeOrderID,
        string takeOrderID,
        string indexed pair,
        uint256 price
    );

    constructor(uint256 _fee){
        admin = msg.sender;
        fee = _fee; 
        feesAccount = msg.sender; 
        tradesAccount = msg.sender;

    }

    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        admin = _newAdmin;
    }

    function setFees(uint256 _newFee) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        fee = _newFee;
    }

    function setFeesAccount(address _feesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        feesAccount = _feesAccount;
    }

    function setTradesAccount(address _tradesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        tradesAccount= _tradesAccount;
    }

    function depositAVAX(uint256 _amount) external payable {
        require(msg.value == _amount, "Beetrade: Please Deposit Right Amount");
        tokensBalances[AVAX][msg.sender].available += msg.value;
        emit Deposit(AVAX, msg.sender, _amount);
    }

    function depositToken(address _token, uint256 _amount) external {
        // make sure user has called approve() function first
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Beetrade: Transfer Failed");
        tokensBalances[_token][msg.sender].available += _amount;
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdrawAVAX(uint256 _amount) external {
        require(tokensBalances[AVAX][msg.sender].available >= _amount, "Beetrade: Insufficient Balance");
        tokensBalances[AVAX][msg.sender].available -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(AVAX, msg.sender, _amount);

    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(tokensBalances[_token][msg.sender].available >= _amount, "Beetrade: Insufficient Balance");
        tokensBalances[_token][msg.sender].available -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }

    function getAvailableAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].available;
    }

    function getLockedAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].locked;
    }

    function getAvailableTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].available;
    }

    function getLockedTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].locked;
    }

    function calculateFee(uint256 _amount) internal view returns(uint256) {
        return ((_amount * fee) / (100 * 1e18));
    }

    function createOrder(
        uint256 _amount, 
        string memory _buySell, 
        string memory _date, 
        string memory _orderType, 
        string memory _pair, 
        uint256 _price, 
        string memory _orderID, 
        address _token
    ) external returns(bool){
        // make sure user has the required token balance
        require(tokensBalances[_token][msg.sender].available >= _amount, "Beetrade Insufficient Balance");
        // move from available to locked balance
        tokensBalances[_token][msg.sender].available -= _amount;
        tokensBalances[_token][msg.sender].locked += _amount;
        usersOrders[msg.sender][_orderID] = true;

        emit CreateOrder(msg.sender, _amount, _buySell, _date, _orderType, _pair, _price, _orderID);
        return true;
    }

    function cancelOrder(string memory _pair, string memory _orderType, string memory _orderID, uint256 _amount, address _token) external returns(bool){
        // make sure the user has the required order balance
        require(tokensBalances[_token][msg.sender].locked >= _amount, "Beetrade Insufficient Balance");
        // make sure order is still valid
        require(usersOrders[msg.sender][_orderID] == true, "Beetrade Order Not Valid");
        // move from locked balance to available
        tokensBalances[_token][msg.sender].locked -= _amount;
        tokensBalances[_token][msg.sender].available += _amount;
        usersOrders[msg.sender][_orderID] = false;

        emit CancelOrder(msg.sender, _pair, _orderType, _orderType);
        return true;
    }

    function singleTrade (
        address maker, 
        address taker, 
        address tokenGet, 
        address tokenGive, 
        uint256 amountGet, 
        uint256 amountGive,
        string memory makeOrderID,
        string memory takeOrderID,
        string memory pair,
        uint256 price
    ) external {
        require(msg.sender == tradesAccount, "Beetrade: Only Trades Account can Execute Trades");
        require(tokensBalances[tokenGet][taker].locked >= amountGet, "Beetrade: Insufficient Balances For Trade"); // Make sure taker has enough balance to cover the trade
        require(tokensBalances[tokenGive][maker].locked >= amountGive, "Beetrade: Insufficient Balances For Trade"); // Make sure maker has enough balance to cover the trade

        uint256 makerFee = calculateFee(amountGet);
        uint256 takerFee = calculateFee(amountGive);


        // subtract from takers balance and add to makers balance for tokenGet
        tokensBalances[tokenGet][taker].locked -= amountGet;
        tokensBalances[tokenGet][maker].available += (amountGet - makerFee);
        tokensBalances[tokenGet][feesAccount].available += makerFee; //charge trade fees

        // subtract from the makers balance and add to takers balance for tokenGive
        tokensBalances[tokenGive][maker].locked -=  amountGive;
        tokensBalances[tokenGive][taker].available += (amountGive - takerFee);
        tokensBalances[tokenGive][feesAccount].available += takerFee; // charge trade fees

        emit Trade(maker, taker, amountGet, amountGive, makeOrderID, takeOrderID, pair, price);
    }

    

}