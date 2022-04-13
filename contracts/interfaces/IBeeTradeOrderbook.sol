pragma solidity >=0.5.0;

interface IBeeTradeOrderbook {
    // event OrderCreated(address indexed token0, address indexed token1, address pair, uint);
    function setAdmin(address _newAdmin) external;
    function setFees(uint256 _newFee) external; 
    function setFeesAccount(address _feesAccount) external;

    function depositAVAX(uint256 _amount) external payable;
    function depositToken(address _token, uint256 _amount) external;
    function withdrawAVAX(uint256 _amount) external;
    function withdrawToken(address _token, uint256 _amount) external;
    function getAvailableAVAXBalance() external view returns(uint256);
    function getAvailableTokenBalance(address token) external view returns(uint256);
    function getLockedAVAXBalance() external view returns(uint256);
    function getLockedTokenBalance(address token) external view returns(uint256);

    // function createOrder(
    //     uint256 _amountA, 
    //     uint256 _amountB, 
    //     string memory _buySell, 
    //     string memory _date, 
    //     string memory _filledAmount, 
    //     string memory _id, 
    //     string memory _orderType,
    //     string memory pair,
    //     uint256 price,
    //     uint256 volume
    // ) external view;
    
    // function cancellOrder() external view;

    // function updateBalance() external view;

    
}

// deposit