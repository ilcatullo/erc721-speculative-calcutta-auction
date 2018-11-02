pragma solidity ^0.4.24;

// Time Committed; 7-10 hours
// Author; Samuel JJ Gosling 
// Github; @samgos

import "./addressSet.sol";
import "./Signidice.sol";
import "./SafeMath.sol";

// ERC20 proxy inteface to externally call to the EIP standard 

interface ERC20 {

    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address subject, uint amount) external returns (bool);
    function balanceOf(address subject) external view returns (uint);

}

// ERC721 proxy inteface to externally call to the EIP standard 

interface ERC721 {

  function transferFrom(address from, address to, uint256 tokenId) external;
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);

}

contract ESCA is Signidice {

  // Defining Libraries

  using addressSet for addressSet._addressSet;
  using SafeMath for uint;

  // Creating address based storage for participants

  mapping(address => mapping (uint => addressSet._addressSet)) internal speculator;
  mapping(address => mapping (uint => addressSet._addressSet)) internal punter;
  mapping(address => mapping (address => address)) public estimate;
  mapping(address => mapping (uint => address)) public merchant;
  mapping(address => mapping (uint => uint)) public value;

  // Defining public variables

  ERC721 public nonFungible;
  ERC20 public wager;

  uint public tokenConstant;
  uint public houseFee;
  uint public tokenFee;
  address public admin;

  // Defining ownership conditioning 

  modifier _onlyAdmin { require(msg.sender == admin); _; }

  // Defining constructor conditions
    
  constructor () public {
    tokenConstant = uint(10**18);
    houseFee = uint(2500000);
    admin = msg.sender;
  }
  
  // Defining the ERC20 wager token contract location on-chain

  function defineWager(address _source) public _onlyAdmin {
     wager = ERC20(_source);
  }
  
  // Defining the ERC721 collectables token contract location on-chain

  function defineSource(address _target) public pure returns (ERC721 item) {
    item = ERC721(_target);
  }

  // A operation to be executed if a colllectable holder wishes to submit their asset
  // to market and recieve a monetary value higher than the normal exchange rate.

  function sellCollectable(address _source, uint _tokenId, uint _marketValue) public {
    require(defineSource(_source).ownerOf(_tokenId) == msg.sender);
    require(merchant[_source][_tokenId] == address(0x0));
    require(_marketValue > 0);
    defineSource(_source).transferFrom(msg.sender, address(this), _tokenId);
    merchant[_source][_tokenId] = msg.sender;
    value[_source][_tokenId] = _marketValue;
  }

  // An operation to be executed if a colllectable holder wishes to submit their asset
  // to market and recieve a monetary value higher than the normal exchange rate.
  
  function tieredWager(address _source, uint _tokenId, uint _marketValue) public payable {
    require(value[_source][_tokenId].div(_marketValue).div(4) == _marketValue);
    require(!punter[_source][_tokenId].contains(msg.sender));
    require(msg.value == value[_source][_tokenId].div(4));
    require(merchant[_source][_tokenId] != address(0x0));
    require(punter[_source][_tokenId].length() <= uint(3));
    punter[_source][_tokenId].insert(msg.sender);
  }
  
  // An implementation to allow external user's to bet on the underlying wager based exchange system 

  function speculativeWager(address _source, address _outcome, uint _tokenId, uint _wagerAmount, uint _marketValue) public {
    require(value[_source][_tokenId].div(_marketValue) == _wagerAmount.div(tokenConstant));
    require(!speculator[_source][_tokenId].contains(msg.sender));
    require(value[_source][_tokenId].div(4) == _wagerAmount);
    require(punter[_source][_tokenId].contains(_outcome));
    speculator[_source][_tokenId].insert(msg.sender);
    require(punter[_source][_tokenId].length() <= 3);
    estimate[msg.sender][_source] = _outcome;
    wager.transferFrom(msg.sender, address(this), _wagerAmount);
  }
  
  // Function to generate a winner and if no speculative estimates are correct the pot multiples for the next round

  function generateWinners(uint[2][] ranges, bytes _entropy, address _source, uint _tokenId) public _onlyAdmin {
    require(merchant[_source][_tokenId] != address(0x0));
    require(speculator[_source][_tokenId].length() == 4);
    require(tokenFee < wager.balanceOf(address(this)));
    uint[] memory entropyGen = generateRnd(ranges, _entropy);
    uint randomness;
    address _guess;

    for(uint x = 0; x < entropyGen.length; x++){
        randomness = entropyGen[x];
        if(randomness <= 4) break;
    }
    
    address _risk = punter[_source][_tokenId].members[randomness];

    for(uint y = 0; y < speculator[_source][_tokenId].length();  y++){
        
        _guess = speculator[_source][_tokenId].members[y];
        if(estimate[_guess][_source] == _risk) break;
        else if(estimate[_guess][_source] == _risk && 
            y == speculator[_source][_tokenId].length()) _guess == address(0x0);
    }

    address _sell = merchant[_source][_tokenId];
    rewardWinners(_source, _tokenId, _sell, _risk, _guess);
    removeParticipants(_source, _tokenId);
  }
  
  // Exuection to reward winners
  
  function rewardWinners(address _source, uint _tokenId, address _ercMerchant, address _speculativeWinner, address _wagerWinner) internal {
    uint tokenPot = wager.balanceOf(address(this)).sub(tokenFee);
    uint ethPot = address(this).balance.sub(houseFee);
    if(_wagerWinner != address(0x0)) wager.transfer(_speculativeWinner, tokenPot);
    wager.transfer(_ercMerchant, tokenFee);
    removeParticipants(_source, _tokenId);
    defineSource(_source).transferFrom(address(this), _wagerWinner, _tokenId);
    _ercMerchant.transfer(ethPot);
    admin.transfer(houseFee);
  }
  
  // Function to remove data

  function removeParticipants(address _source, uint _tokenId) internal {
    delete speculator[_source][_tokenId];
    delete merchant[_source][_tokenId];
    delete punter[_source][_tokenId];

  }

}
