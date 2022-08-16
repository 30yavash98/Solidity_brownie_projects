// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Blast is Ownable , VRFConsumerBase{
    uint256 public entranceFeeAmount;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomness;
    uint256 public randomRatio; 
    uint256 public winnerCounter;
    AggregatorV3Interface internal entranceFeeContract;
    enum BLAST_STATUS{
        OPEN,
        CLOSE,
        CALCULATING
    }
    BLAST_STATUS public blast_status;

    event requestIdRandomness(bytes32 requestId);
    
    // the minimum amount of entrance fee is 5 $
    
    constructor(address _entranceFeeAddress , address _vrfcoordinator , address _link , bytes32 _keyhash , uint256 _fee) public VRFConsumerBase(_vrfcoordinator , _link){
        blast_status = BLAST_STATUS.CLOSE;
        keyHash = _keyhash;
        fee = _fee;
        winnerCounter = 0;
        entranceFeeAmount = 5 * (10**18);
        entranceFeeContract = AggregatorV3Interface(_entranceFeeAddress);
    }
    
    // storing information of players for payment
    
    struct info{
        address payable account;
        uint256 money;
        uint256 ratio;
    }

    info[] public players;

    function entranceFee() public view returns(uint256){
        ( ,int price, , , ) = entranceFeeContract.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10); //18 decimal,'price' 8 decimal dare
        uint256 costToEnter = entranceFeeAmount * (10**18) / adjustedPrice; //vooroodi be wei
        return costToEnter;
    }
    
    // NOTE: in solidity unfortunately we can't use decimal numbers, so we get the ratios multiplied by 100
    // and in the payment function, we divide the ratios by 100
    
    function enter(uint256 _ratio) payable public{
        require(blast_status == BLAST_STATUS.OPEN);
        require(msg.value >= entranceFee() , "not enough money for blast!!!");
        require(_ratio > 100 && _ratio <= 1000 , "incorrect ratio!!!");
        players.push(info(payable(msg.sender) , msg.value , _ratio));
    }
    function start() public onlyOwner{
        require(blast_status == BLAST_STATUS.CLOSE);
        blast_status = BLAST_STATUS.OPEN;
    }

    function finish() public onlyOwner returns(bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        blast_status = BLAST_STATUS.CALCULATING;
        requestId = requestRandomness(keyHash, fee);
        return requestId;
        emit requestIdRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        require(blast_status == BLAST_STATUS.CALCULATING , "blast is not ended!!!");
        require(_randomness > 0 , "there is no random number yet!!!");
        randomness = _randomness;
    }
    
    // with this function , we fund our contract
    
    function charge() payable public onlyOwner{
        require(msg.value > 0 , "its not charged!!!");
    }
    
    // here we have logic of our random ratios and chance , the chance of being between 1 and 2 , is 570-20/1000 = 55%
    // or the chance of being 0 is 20-0/1000 = 2% and the rest are calculated in this way (top+1-bottom/1000)
    
    function getRatio() public onlyOwner{
        require(blast_status == BLAST_STATUS.CALCULATING, "blast is not ended!!!");
        uint256 modulus = randomness % 1000;
        uint256 top;
        uint256 down;
        if (modulus <= 19 && modulus >= 0 ){
            randomRatio = 0;
        }
        else if (modulus <= 569 && modulus >= 20 ){
            top = 570;
            down = 20;
            randomRatio = (modulus-down)*100/(top-down) + 100;
        }
        else if (modulus <= 779 && modulus >= 570 ){
            top = 780;
            down = 570;
            randomRatio = (modulus-down)*100/(top-down) + 200;
        }
        else if (modulus >= 780 && modulus <= 879 ){
            top = 880;
            down = 780;
            randomRatio = (modulus-down)*100/(top-down) + 300;
        }
        else if (modulus >= 880 && modulus <= 929 ){
            top = 930;
            down = 880;
            randomRatio = (modulus-down)*100/(top-down) + 400;
        }
        else if (modulus >= 930 && modulus <= 959 ){
            top = 960;
            down = 930;
            randomRatio = (modulus-down)*100/(top-down) + 500;
        }
        else if (modulus >= 960 && modulus <= 979 ){
            top = 570;
            down = 20;
            randomRatio = (modulus-down)*100/(top-down) + 600;
        }
        else if (modulus >= 980 && modulus <= 989 ){
            top = 990;
            down = 980;
            randomRatio = (modulus-down)*100/(top-down) + 700;
        }
        else if (modulus >= 990 && modulus <= 994 ){
            top = 995;
            down = 990;
            randomRatio = (modulus-down)*100/(top-down) + 800;
        }
        else if (modulus >= 995 && modulus <= 998 ){
            top = 999;
            down = 995;
            randomRatio = (modulus-down)*100/(top-down) + 900;
        }
        else if (modulus == 999 ){
            randomRatio = 10;
        }
    }

        function blastPayment() public onlyOwner{
        require(blast_status == BLAST_STATUS.CALCULATING, "blast is not ended!!!");
        for (uint256 i=0 ; i < players.length ; i++){
            if(randomRatio > 0){
                uint256 playerRatio = players[i].ratio;
                if (playerRatio <= randomRatio){
                    uint256 playerValue = players[i].money / 100 * players[i].ratio;
                    address payable playerAddress = players[i].account;
                    bool send_status = playerAddress.send(playerValue);
                    require(send_status , "sending Failed!!!");
                    winnerCounter++;
                }
            }
        }
        delete players;
        blast_status = BLAST_STATUS.CLOSE;
        }
        
    
}
