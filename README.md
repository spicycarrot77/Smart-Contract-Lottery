# 🎰 Smart Contract Lottery (EVM)

This project is a **decentralized lottery smart contract** built on an **EVM-compatible blockchain**.  
Users can enter the lottery by sending ETH, and a **random winner** is selected using **Chainlink Verifiable Randomness (VRF)**. The winner receives the entire lottery pool **minus a small organizer fee**.

The main goal of this project was to understand **how to build a fair, trustless lottery on-chain**, without relying on any centralized randomness or manual intervention.

---

##  What this project does

- Users participate by sending **ETH**
- A **minimum ETH amount** is required to enter
- All participants are stored on-chain
- A winner is selected using **Chainlink VRF**
- The winner receives the full prize pool (after fees)
- The entire process is handled by the smart contract

---

##  How the Lottery Works

### 1. Entering the Lottery
- Any user can enter by sending at least the minimum required ETH.
- Each valid entry is recorded as a participant.

### 2. Requesting Randomness
- When the lottery is ready to be closed, the contract requests a random number from **Chainlink VRF**.

### 3. Picking the Winner
- Chainlink returns a provably random number.
- The random value is used to select a winner from the list of participants.

### 4. Paying Out
- The total ETH balance of the contract is calculated.
- A small organizer fee is deducted.
- The remaining ETH is transferred to the winner automatically.

---

##  Why Chainlink VRF?

On-chain randomness is difficult to do securely. Using values like `block.timestamp` or `blockhash` can be manipulated.

Chainlink VRF provides:
- Cryptographically secure randomness
- Proof that the random number wasn’t manipulated
- A decentralized oracle solution

This ensures the lottery is **fair and trustless**.

---

##  Tech Stack

- **Solidity** – Smart contract language
- **EVM-compatible blockchain** (Ethereum / testnets)
- **Chainlink VRF** – Secure random number generation
- **Foundry** – Development and testing

---

##  Important Parameters

- **Minimum Entry Amount**  
  The minimum ETH required to participate in the lottery.

- **Organizer Fee**  
  A small percentage taken from the prize pool.

- **Chainlink VRF Configuration**
  - Subscription ID  
  - Key Hash  
  - Callback Gas Limit  

---

##  Security Notes

- Uses **Chainlink VRF** for randomness
- No manual winner selection
- No centralized control over results
- Funds are handled entirely on-chain
- Reentrancy-safe payout logic is recommended

> ⚠️ This project is intended for learning purposes. Always test thoroughly on testnets before deploying to mainnet.

---

## 📌 Example

- 3 users enter with 0.1 ETH each

- Total Pool: 0.3 ETH
- Organizer Fee (5%): 0.015 ETH
- Winner Gets: 0.285 ETH


The winner is selected randomly using Chainlink VRF.

---

##  Testing Ideas

- Test minimum ETH enforcement
- Test lottery entry logic
- Test randomness fulfillment
- Test winner selection
- Test ETH payout to winner
- Test edge cases (single participant, low balance, etc.)

---

## 📄 License

MIT License

---

