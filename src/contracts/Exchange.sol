pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Token.sol";
contract Exchange {
    using SafeMath for uint256;
    address public feeAccount; //the account that recieves the exchange fees
    uint256 public feePercent; //the fee percentage
    address constant ETHER = address(0); //store Ether in tokens mapping with blank address
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => _Order) public orders; // a way to store the order
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;

    // events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );
    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
        );
    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
        );
    
    //a way to model the order
    struct _Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }


    constructor(address _feeAccount, uint256 _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }
    //fallback reverts if Ether is sent to this smart contract by mistake
    function() external {
        revert();
    }
    function depositEther() public payable {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }
    function withdrawEther(uint256 _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount); //make sure user has more ether than the tx requires
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }
    function depositToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        // which token are we depositing?
        // How much?
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        // Send tokens to this contract
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        // Track the balance
        // Emit event
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }
    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != address(0));
        require(tokens[_token][msg.sender] >= _amount);
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }

    //add the order to storage
    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
        emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    }

    function cancelOrder(uint256 _id) public{
        _Order storage _order = orders[_id];
        //Must be "my" order
        require(address(_order.user) == msg.sender);
        //Must be a valid order
        require(_order.id == _id);
        orderCancelled[_id] = true;
        emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    }
}
/*
TODO:
    [x] Set the fee account
    [x] Deposit Ether
    [x] Withdrawl ether
    [x] Deposit tokens
    [x] Withdrawl tokens
    [x] Check balances
    [x] Make Order
    [x] Cancel Order
    [] Fill Order
    [] Charge fees
*/