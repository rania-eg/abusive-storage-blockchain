# 🛡️ Blockchain-Based System to Detect and Prevent Hoarding of Essential Products

This is our end-of-year PCD (Projet de Conception et Développement) project at ENSI. We developed a decentralized application (DApp) that leverages blockchain technology to detect and prevent the **abusive storage (hoarding)** of essential goods such as sugar, milk, and flour. By using Ethereum smart contracts, our system brings transparency, traceability, and security to the supply chain.

---

## 🚀 Features

- 🧾 Immutable transaction records
- 🔍 Detection of unusual buying/selling behavior
- 🔐 Trustless, decentralized enforcement using smart contracts
- 🧪 Local testing via Truffle and Ganache
- 🌐 Metamask integration for secure user authentication

---

## ⚙️ Tech Stack

- **Solidity** – Smart contract language  
- **Ethereum** – Blockchain platform  
- **Truffle** – Smart contract development framework  
- **Ganache** – Local Ethereum blockchain for testing  
- **React.js** – Frontend UI framework  
- **Web3.js / ABI** – Interaction with the Ethereum blockchain  
- **Metamask** – Ethereum wallet and DApp login

---

## 💻 Getting Started

### ✅ Prerequisites

Make sure the following are installed on your machine:

- [Node.js & npm](https://nodejs.org/)
- [Truffle Suite](https://trufflesuite.com/truffle/)
- [Ganache](https://trufflesuite.com/ganache/)
- [Metamask](https://metamask.io/)
- React environment (e.g., Create React App or Vite)

---

### 🧪 Local Setup Instructions

1. **Clone the repository**

```bash
git clone https://github.com/Ansem23/abusive-storage-detection.git
cd abusive-storage-detection
```

2. **Install frontend dependencies**

Navigate to the frontend directory called `client`  and run:

```bash
cd frontend
npm install
```
3. **Start Ganache**

Open the Ganache application

Click "Quickstart" or open your existing workspace

Copy the RPC server URL (usually http://127.0.0.1:7545)

Keep Ganache running in the background

4.**Compile and migrate the smart contracts**

From the root of the project (where your truffle-config.js is located):

```bash
truffle compile
truffle migrate
```
5.**Connect Metamask to Ganache**

Open your browser and unlock Metamask

Click the network dropdown > Add Network manually

Network Name: Ganache

RPC URL: http://127.0.0.1:7545

Chain ID: 1337 or 5777 (match what's shown in Ganache)

Import an account:

Copy one of the private keys from Ganache

In Metamask: Import Account > paste the private key

6.**Run the frontend app**

Now that your contracts are deployed and Metamask is connected:

```bash
npm start
```

!!!
Please note that the value of the contract adress in the frontend pages should change to reflect the deplyoed contract on your virtual blockchain. This can't be hardcoded because each time the contract is deployed the contract changes.
!!!

This launches the React frontend at http://localhost:3000/, where your DApp will be fully functional and connected to the local Ethereum network.
