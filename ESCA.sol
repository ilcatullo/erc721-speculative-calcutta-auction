pragma solidity ^0.4.24;

import "./addressSet.sol";
import "./SafeMath.sol";

interface ERC20 {

    function transfer(address subject, uint amount) external returns (bool);
    function balanceOf(address subject) external view returns (uint);

}

interface ERC721 {

  function getApproved(uint256 tokenId) public view returns (address operator);
  function transferFrom(address from, address to, uint256 tokenId) public;
  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);
  function approve(address to, uint256 tokenId) public;

}

contract ESCA {

  // Defining Libraries

  using addressSet for addressSet._addressSet;
  using SafeMath for uint;

  // Creating address based storage for participants

  addressSet._addressSet internal _spec;
  addressSet._addressSet internal _punt;

  mapping(address => mapping (uint => address)) public merchant;
  mapping(address => mapping (uint => _spec)) public speculator;
  mapping(address => mapping (uint => _punt)) public punter;
  mapping(address => mapping (uint => uint)) public value;

  // Defining public variables

  ERC721 public nonFungible;
  ERC20 public wager;

  uint public tokenConstant;
  address public admin;

  // Defing ownership conditions

  modifier _onlyAdmin { require(msg.sender == admin); _; }

  constructor () public {
    tokenConstant = uint(10**18);
    admin = msg.sender;
  }

  function defineWager(address _source) public _onlyAdmin {
     wager = ERC20(_source);
  }

  function defineSource(address _target) internal returns (nonFungible item) {
    item = ERC721(_target);
  }

  function sellCollectable(address _source, uint _tokenId, uint _marketValue) public {
    require(defineSource(_source).ownerOf(_tokenId) == msg.sender);
    require(merchant[_source][tokenId] == address(0x0));
    require(_marketValue > 0);
    nonFungible.transferFrom(msg.sender, address(this), _tokenId);
    merchant[_source][_tokenId] = msg.sender;
    value[_source][_tokenId] = _marketValue;
  }

  function tieredWager(address _source, uint _tokenId, uint _marketValue) public payable {
    require(value[_source][_tokenId].div(_marketValue) == _wagerAmount.div(tokenConstant));
    require(!punter[_source][_tokenId].contains(msg.sender));
    require(msg.value == value[_source][_tokenId].div(4));
    require(merchant[_source][_tokenId] != address(0x0));
    require(punter[_source][_tokenId].length <= 3);
    punter[_source][_tokenId].insert(msg.sender);
  }

  function speculativeWager(address _outcome, uint _tokenId, uint _entryWager) public {
    require(!speculator[_source][_tokenId].contains(msg.sender));
    require(value[_tokenId].div(4) == _entryWager);
    require(punter[_tokenId].contains(_outcome));
    wager.transferFrom(msg.sender, address(this), _wagerAmount);
    speculator[_tokenId].insert(msg.sender);
}
