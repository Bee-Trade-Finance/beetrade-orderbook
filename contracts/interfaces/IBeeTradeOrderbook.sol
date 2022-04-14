pragma solidity >=0.5.0;

interface IBeeTradeOrderbook {
    
    function setAdmin(address _newAdmin) external;
    function setFees(uint256 _newFee) external; 
    function setFeesAccount(address _feesAccount) external;
    function setTradesAccount(address _tradesAccount) external;

    function depositAVAX(uint256 _amount) external payable;
    function depositToken(address _token, uint256 _amount) external;
    function withdrawAVAX(uint256 _amount) external;
    function withdrawToken(address _token, uint256 _amount) external;
    function getAvailableAVAXBalance() external view returns(uint256);
    function getAvailableTokenBalance(address token) external view returns(uint256);

    function calculateFee(uint256 amount) external view returns(uint256);
    
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
    ) external;
}