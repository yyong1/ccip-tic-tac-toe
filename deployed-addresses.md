✅ Tic Tac Toe Demo deployed at address 0x6A00077dE2b56d8E488F765fea3Eee002DA202eb on ethereumSepolia blockchain
✅ Tic Tac Toe Demo deployed at address 0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48 on avalancheFuji blockchain

❯ npx hardhat ttt-start --source-blockchain ethereumSepolia --sender 0x42e442806Cc79113D9Df994B085C1b6585d65661 --destination-blockchain avalancheFuji --receiver 0x42e442806Cc79113D9Df994B085C1b6585d65661
ℹ️ Attempting to send the message from the TTTDemo smart contract (0x42e442806Cc79113D9Df994B085C1b6585d65661) on the ethereumSepolia blockchain to the TTTDemo smart contract (0x42e442806Cc79113D9Df994B085C1b6585d65661 on the avalancheFuji blockchain)

✅ Message sent, game session created! transaction hash: 0x5fbb3ccdf8945c28c21306fc2ee58724be62605342d9ba6d7dbef6e6791f85b7

❯ npx hardhat ttt-check-winner --blockchain ethereumSepolia --contract 0x6A00077dE2b56d8E488F765fea3Eee002DA202eb --session-id 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681
ℹ️ Attempting to get details of sessionId 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681 from the TTTDemo smart contract (0x6A00077dE2b56d8E488F765fea3Eee002DA202eb) on the ethereumSepolia
winner of sessionId 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681 is: 0x0000000000000000000000000000000000000000
❯ npx hardhat ttt-check-winner --blockchain avalancheFuji --contract 0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48 --session-id 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681
ℹ️ Attempting to get details of sessionId 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681 from the TTTDemo smart contract (0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48) on the avalancheFuji
winner of sessionId 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681 is: 0x42e442806Cc79113D9Df994B085C1b6585d65661

https://testnet.snowtrace.io/address/0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48/events

https://sepolia.etherscan.io/address/0x6A00077dE2b56d8E488F765fea3Eee002DA202eb

https://ccip.chain.link/status?networkType=testnet&search=sepo#/side-drawer/msg/0x421688c8ec701f0ec38b02f89ca5ba0ab451825992ed373ae881d95bb07e986d

---

new section with new contracts

# CCIP Tic-Tac-Toe Demo — Deployment & Usage

This document summarizes the deployment addresses, CLI commands, explorer links, and next steps for running a cross-chain Tic-Tac-Toe demo using Chainlink CCIP.

---

## 1. Deployed Contract Addresses

| Network          | Contract Address                             |
| ---------------- | -------------------------------------------- |
| Ethereum Sepolia | `0x6A00077dE2b56d8E488F765fea3Eee002DA202eb` |
| Avalanche Fuji   | `0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48` |

<details>
<summary>Updated deployments</summary>

| Network          | Contract Address                             |
| ---------------- | -------------------------------------------- |
| Avalanche Fuji   | `0x0081576a8F1ba51811ccE2d95B52C0457f9041E1` |
| Ethereum Sepolia | `0x25Ec5F66e5DDF9e9909E7fcB1A4Ee77FDF01De37` |

</details>

---

## 2. Starting a Game (Sepolia → Fuji)

```bash
npx hardhat ttt-start \
  --source-blockchain ethereumSepolia \
  --sender 0x42e442806Cc79113D9Df994B085C1b6585d65661 \
  --destination-blockchain avalancheFuji \
  --receiver 0x42e442806Cc79113D9Df994B085C1b6585d65661
```

> ℹ️ **Sent:** transaction hash `0x5fbb3ccd...91f85b7` — game session created!

### Check Winner (Session ID: `0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681`)

```bash
# On Sepolia (should be zero address)
 npx hardhat ttt-check-winner \
   --blockchain ethereumSepolia \
   --contract 0x6A00077dE2b56d8E488F765fea3Eee002DA202eb \
   --session-id 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681

# On Fuji (should be player address)
 npx hardhat ttt-check-winner \
   --blockchain avalancheFuji \
   --contract 0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48 \
   --session-id 0x4c06fcc2e01fad4d40cf6985df88baea439f6c4dc14c729b72cfdc511f707681
```

---

## 3. Explorer & CCIP Links

- **Fuji Events**: [https://testnet.snowtrace.io/address/0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48/events](https://testnet.snowtrace.io/address/0xe0440E65E840eFEfc185DBEe8f05D31985FdEd48/events)
- **Sepolia Contract**: [https://sepolia.etherscan.io/address/0x6A00077dE2b56d8E488F765fea3Eee002DA202eb](https://sepolia.etherscan.io/address/0x6A00077dE2b56d8E488F765fea3Eee002DA202eb)
- **CCIP Status**: [https://ccip.chain.link/status?networkType=testnet\&search=sepo#/side-drawer/msg/0x421688c8ec701f0ec38b02f89ca5ba0ab451825992ed373ae881d95bb07e986d](https://ccip.chain.link/status?networkType=testnet&search=sepo#/side-drawer/msg/0x421688c8ec701f0ec38b02f89ca5ba0ab451825992ed373ae881d95bb07e986d)

---

## 4. Router Update Steps

```bash
# Update Sepolia router
npx hardhat ttt-update-router \
  --blockchain ethereumSepolia \
  --contract 0x25Ec5F66e5DDF9e9909E7fcB1A4Ee77FDF01De37 \
  --router 0x0bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59

# Update Fuji router
npx hardhat ttt-update-router \
  --blockchain avalancheFuji \
  --contract 0x0081576a8F1ba51811ccE2d95B52C0457f9041E1 \
  --router 0xf694e193200268f9a4868e4aa017a0118c9a8177
```

---

## 5. Next Steps

1. **Start a new game** using the latest deployed contracts on the Fuji client.
2. **Observe** the CCIP explorer screenshot below to verify the message flow.

![CCIP Explorer — Fuji to Sepolia message trace](img/ccip-explorer-screenshot.png)
