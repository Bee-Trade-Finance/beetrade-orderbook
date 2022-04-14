pragma solidity >=0.5.0;

import './interfaces/IERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BeeTradeOrderbook {
    using SafeMath for uint256;

    address public admin; // the admin address
    uint256 public fee; //percentage times (1 ether)
    address public feesAccount; //the account that will receive fees
    address public tradesAccount; // the address that can execute trades
    address AVAX = address(0); // using the zero address to represent avax token

    mapping (address => mapping (address => uint256)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event Trade(
        uint256 amountGet, 
        uint256 amountGive,
        string indexed makeOrderID,
        string indexed takeOrderID,
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
        tokensBalances[AVAX][msg.sender] = SafeMath.add(tokensBalances[AVAX][msg.sender], msg.value);
        emit Deposit(AVAX, msg.sender, _amount);
    }

    function depositToken(address _token, uint256 _amount) external {
        // make sure user has called approve() function first
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Beetrade: Transfer Failed");
        tokensBalances[_token][msg.sender] = SafeMath.add(tokensBalances[_token][msg.sender], _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdrawAVAX(uint256 _amount) external {
        require(tokensBalances[AVAX][msg.sender] <= _amount, "Beetrade: Insufficient Amount");
        payable(msg.sender).transfer(_amount);
        tokensBalances[AVAX][msg.sender] = SafeMath.sub(tokensBalances[AVAX][msg.sender], _amount);
        emit Withdraw(AVAX, msg.sender, _amount);

    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(tokensBalances[_token][msg.sender] <= _amount, "Beetrade: Insufficient Amount");
        IERC20(_token).transfer(msg.sender, _amount);
        tokensBalances[_token][msg.sender] = SafeMath.sub(tokensBalances[_token][msg.sender], _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }

    function getAvailableAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender];
    }

    function getAvailableTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender];
    }

    function calculateFee(uint256 amount) internal view returns(uint256) {
        return ((amount * fee) / (100 * 1e18));
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
        require(tokensBalances[tokenGet][taker] >= amountGet, "Beetrade: Insufficient Balances For Trade"); // Make sure taker has enough balance to cover the trade
        require(tokensBalances[tokenGive][maker] >= amountGive, "Beetrade: Insufficient Balances For Trade"); // Make sure maker has enough balance to cover the trade

        uint256 makerFee = calculateFee(amountGet);
        uint256 takerFee = calculateFee(amountGive);


        // subtract from takers balance and add to makers balance for tokenGet
        tokensBalances[tokenGet][taker] = SafeMath.sub(tokensBalances[tokenGet][taker], amountGet);
        tokensBalances[tokenGet][maker] = SafeMath.add(tokensBalances[tokenGet][maker], SafeMath.sub(amountGet, makerFee));
        tokensBalances[tokenGet][tradesAccount] = SafeMath.add(tokensBalances[tokenGet][tradesAccount], makerFee); //charge trade fees

        // subtract from the makers balance and add to takers balance for tokenGive
        tokensBalances[tokenGive][maker] = SafeMath.sub(tokensBalances[tokenGive][maker], amountGive);
        tokensBalances[tokenGive][taker] = SafeMath.add(tokensBalances[tokenGive][taker], SafeMath.sub(amountGive, takerFee));
        tokensBalances[tokenGive][tradesAccount] = SafeMath.add(tokensBalances[tokenGive][tradesAccount], takerFee);

        emit Trade(amountGet, amountGive, makeOrderID, takeOrderID, pair, price); // charge trade fees
    }

    

}