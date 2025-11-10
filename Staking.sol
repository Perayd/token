// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    IERC20 public immutable stakingToken;

    uint256 public rewardRatePerSecond; // reward tokens per second distributed to stakers
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;

    constructor(address _stakingToken, uint256 _rewardRatePerSecond) {
        stakingToken = IERC20(_stakingToken);
        rewardRatePerSecond = _rewardRatePerSecond;
        lastUpdateTime = block.timestamp;
    }

    /* ========== VIEWS ========== */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) { return rewardPerTokenStored; }
        uint256 delta = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (delta * rewardRatePerSecond * 1e18 / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return (balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    /* ========== MUTATIVE ========== */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply += amount;
        balances[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");
        }
    }

    /* ========== RESTRICTED (owner/admin would call) ========== */
    // For simplicity we allow an external account to top up rewards by transferring tokens to the contract
    function notifyRewardAmount(uint256 extra) external updateReward(address(0)) {
        // caller should transfer tokens to this contract before calling
        // e.g., MyToken.approve(stakingContract, amount) then transfer
        // No owner checks here for simplicity — consider adding access control in production
        // Reward rate adjustment naïve approach: add extra tokens to distribution over next N seconds
        // For demo: increase rewardRatePerSecond proportionally (simple, not ideal)
        uint256 duration = 7 days;
        rewardRatePerSecond += extra / duration;
    }

    /* ========== MODIFIERS ========== */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}
