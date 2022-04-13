pragma solidity >=0.5.0;

import './interfaces/IBeeTradeOrderbook.sol';
import './interfaces/IERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BeeTradeOrderbook is IBeeTradeOrderbook {
    using SafeMath for uint256;

    address public admin; // the admin address
    uint256 public fee; //percentage times (1 ether)
    address public feesAccount; //the account that will receive fees
    address AVAX = address(0); // using the zero address to represent avax token
    
    struct UserBalance {
        uint256 available;
        uint256 locked;
    }

    struct UserOrder {
        address account;
        uint256 amountA;
        uint256 amountB;
        string buySell;
        string date;
        uint256 filledAmount;
        string id;
        string orderType;
        string pair;
        uint256 price;
        uint256 volume;
    }

    mapping (address => mapping (address => UserBalance)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping(string => UserOrder)) public orders; // mapping of user accounts to mapping of users orders

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

    function depositAVAX(uint256 _amount) external payable {
        require(msg.value == _amount, "Beetrade: Please Deposit Right Amount");
        tokensBalances[AVAX][msg.sender].available = SafeMath.add(tokensBalances[AVAX][msg.sender].available, msg.value);
    }

    function depositToken(address _token, uint256 _amount) external {
        // make sure user has called approve() function first
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Beetrade: Transfer Failed");
        tokensBalances[_token][msg.sender].available = SafeMath.add(tokensBalances[_token][msg.sender].available, _amount);
    }

    function withdrawAVAX(uint256 _amount) external {
        require(tokensBalances[AVAX][msg.sender].available <= _amount, "Beetrade: Insufficient Amount");
        payable(msg.sender).transfer(_amount);
        tokensBalances[AVAX][msg.sender].available = SafeMath.sub(tokensBalances[AVAX][msg.sender].available, _amount);

    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(tokensBalances[_token][msg.sender].available <= _amount, "Beetrade: Insufficient Amount");
        IERC20(_token).transfer(msg.sender, _amount);
        tokensBalances[_token][msg.sender].available = SafeMath.sub(tokensBalances[_token][msg.sender].available, _amount);
    }

    function getAvailableAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].available;
    }

    function getAvailableTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].available;
    }

    function getLockedAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].locked;
    }

    function getLockedTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].locked;
    }

    

}