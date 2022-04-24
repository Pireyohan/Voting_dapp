// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting smart contract
 *
 * @author Pire Yohan
 * @notice You can use this contract to run a simple vote
 * @dev Red Wire for a simple voting system  V3.0 Dapp
 */

contract Voting is Ownable {


    uint public winningProposalID;
    uint public winningProposalIDVoteCount;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;

    /**
     * @dev Emitted when voterAddress is registered to the whitelist via admin.
     */
    event VoterRegistered(address voterAddress); 
    /**
     * @dev Emitted when currentWorkflowStatus  set from previous to new status
     */
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    /**
     * @dev Emitted when proposalId is registered in the proposal array.
     */
    event ProposalRegistered(uint proposalId);
    /**
     * @dev Emitted when voter voted for a proposal via 'proposalId'.
     */
    event Voted (address voter, uint proposalId);

    /**
     * @dev Check is the Msg.sender is a registered voter
     */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @dev Returns Voter details ... Address.. 
     * - 'msg.sender' needs to be a voter.
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }

    /**
     * @dev Returns a proposal détails '_id'
     *  -'msg.sender' needs to be a voter.
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /**
     * @dev Set Voter's address '_addr' as registered.
     *      Register a voter and his addr to the Voters Array 
     *  Emits a {VoterRegistered} event.
     */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /**
     * @dev Add a proposal in the proposal array 'proposalsArray' with a description '_desc'.
     * 
     *  Emits a {ProposalRegistered} event with the proposal's ID.
     */
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); 

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /**
     * @dev Vote to a proposal with the ID '_id'. 
     *  Emits a {Voted} event with the message sender's address and the proposal's ID.
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        if(proposalsArray[_id].voteCount > winningProposalIDVoteCount) {
            winningProposalIDVoteCount = proposalsArray[_id].voteCount;
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //


    /**
     * @dev Sets 'currentWorkflowStatus' from 'WorkflowStatus.RegisteringVoters' to 'WorkflowStatus.ProposalsRegistrationStarted'. 
     *  Emits a {WorkflowStatusChange} event for each address whitelisted.
     */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev Sets 'currentWorkflowStatus' from 'WorkflowStatus.ProposalsRegistrationStarted' to 'WorkflowStatus.ProposalsRegistrationEnded'. 
     *  Emits a {WorkflowStatusChange} event.
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Sets 'currentWorkflowStatus' from 'WorkflowStatus.ProposalsRegistrationEnded' to 'WorkflowStatus.VotingSessionStarted'. 
     *  Emits a {WorkflowStatusChange} event.
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev Sets 'currentWorkflowStatus' from 'WorkflowStatus.VotingSessionStarted' to 'WorkflowStatus.VotingSessionEnded'. 
     *  Emits a {WorkflowStatusChange} event.
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Tally the votes and set the proposal winner (winningProposalId)
     */

   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}