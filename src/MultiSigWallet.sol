// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSigWallet{
    uint public immutable numOfConfirmationsRequired;
    address[] approversData;
    uint txIndex;
    struct Transaction{
        uint transactionIndex;
        address to;
        uint amount;
        uint initiationTime;
        uint confirmationsDone;
        bytes data;
        bool executed;
        bool isDeleted;
    }

    mapping(address=>bool) isApprover;
    mapping(uint=>mapping(address=>bool)) isTransactionConfirmed;
    address public owner;
    Transaction [] public transactions;

    event MoneyReceived(address receiver, address sender, uint amount);
    event MoneySent(address sender, address receiver, uint amount);

    constructor(uint _numOfConfirmationsRequired,address[] memory _approvers) {
        owner = tx.origin;
        isApprover[owner]=true;
        if(_numOfConfirmationsRequired>0){
            bool isNumberOfConfirmationsRequiredValid =  _numOfConfirmationsRequired>0 && _numOfConfirmationsRequired <= _approvers.length;
            require(isNumberOfConfirmationsRequiredValid,"Please enter valid number of confirmations required for a transaction");
            uint len = _approvers.length;
            for(uint i =0;i<len;){
                address approver = _approvers[i];
                require(approver!=address(0),"Invalid Approver");
                require(!isApprover[approver],"Approver not unique");
                isApprover[approver]=true;
                unchecked{
                    ++i;
                }
            }
        }
        numOfConfirmationsRequired = _numOfConfirmationsRequired;
        approversData = _approvers;
    }

    modifier onlyMultiSig(){
        require(numOfConfirmationsRequired>0,"Allowed for multisig wallets only");
        _;
    }
    modifier txExists(uint _txIndex){
        require(transactions[_txIndex].initiationTime>0,"Transaction does not exist");
        _;
    }
    receive() external payable{
        emit MoneyReceived(address(this), msg.sender, msg.value);
        emit MoneySent(msg.sender, address(this), msg.value);
    }

    function initiateTransaction(address _to,uint _amount,bytes calldata _data) external returns(uint) {

        uint _txIndex = txIndex;
        bool isTransactionInitiatedByOwner = owner==tx.origin;//Doublt: does this make our contract more vulnerable?
        require(isTransactionInitiatedByOwner,"Only owner can initaite a transaction");

        uint contractBalance = address(this).balance;
        bool hasEnoughContractBalance = contractBalance >= _amount;
        require(hasEnoughContractBalance,"Not Enough Money in your wallet");

        transactions.push(Transaction(_txIndex,_to,_amount, block.timestamp,1,_data,false, false));
        isTransactionConfirmed[_txIndex][msg.sender] = true;
        return _txIndex;
    }

    function fetchApproverData()public view returns (address[] memory){
        return approversData;
    }

    function fetchTxData()public view returns (uint, uint, uint){
        return (numOfConfirmationsRequired, 1,1);
    }

    function getNumberOfConfirmationsDone(uint _txIndex) external view returns(uint){
        return transactions[_txIndex].confirmationsDone;
    }
    function approveTransaction(uint _txIndex) external onlyMultiSig returns(uint) {
        //TODO: check for deleted transaction
        require(isApprover[msg.sender]==true,"Not an approver");

        bool hasTransactionInitiated = transactions[_txIndex].initiationTime >0;
        require(hasTransactionInitiated,"Please initiate a new transaction");

        bool hasAlreadyApproved = isTransactionConfirmed[_txIndex][msg.sender];
        require(!hasAlreadyApproved,"You have already approved the transaction");

        isTransactionConfirmed[_txIndex][msg.sender]=true;
        transactions[_txIndex].confirmationsDone++;

        return transactions[_txIndex].confirmationsDone;

        // emit TransactionPartiallyApproved(msg.sender,transactions[_txIndex].amount,transactions[_txIndex].confirmationsDone);
        // if(transactions[_txIndex].confirmationsDone==numOfConfirmationsRequired){
        //     publishTransaction(_txIndex); 
        // }
    }

    function getStatusOfYourApproval(uint _txIndex) external view returns(bool) {
        return isTransactionConfirmed[_txIndex][msg.sender];
    }

    function revokeTransaction(uint _txIndex) external onlyMultiSig returns(uint){
        //TODO: check for deleted transaction
        require(isApprover[tx.origin ]==true,"Not an approver");

        bool hasTransactionInitiated = transactions[_txIndex].initiationTime >0;
        require(hasTransactionInitiated,"No transaction to revoke");

        bool hasAlreadyApproved = isTransactionConfirmed[_txIndex][tx.origin];
        require(hasAlreadyApproved,"You have NOT approved the transaction YET");

        isTransactionConfirmed[_txIndex][msg.sender]=false;
        transactions[_txIndex].confirmationsDone--;
        return transactions[_txIndex].confirmationsDone;
        // emit TransactionPartiallyRevoked(_txIndex,msg.sender);

        // if(transactions[_txIndex].confirmationsDone==0){ // Some modifications might be needed here
        //     emit TransactionCompletelyRevoked(_txIndex,transactions[_txIndex].amount);
        // }
    }

    function deleteTransaction(uint _txIndex) external{
        transactions[_txIndex].isDeleted = true;
    }

    function publishTransaction(uint _txIndex) external {
        (bool sent, ) = transactions[_txIndex].to.call{value: transactions[_txIndex].amount}(transactions[_txIndex].data);
        require(sent, "Failed to send Ether");
        transactions[_txIndex].executed=true;
    }

    function getNumberOfConfirmations() view external returns(uint){
        return numOfConfirmationsRequired;
    }

    //TODO: adding and removing approvers

}