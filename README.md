# Foundry DeFi Stablecoin

This is a section of the Cyfrin Solidity Course.

*[⭐️ Updraft | Foundry DeFi Stablecoin](https://updraft.cyfrin.io/courses/advanced-foundry/develop-defi-protocol/defi-decentralized-stablecoin)*

# About

This project is a decentralized overcollateralized stablecoin protocol inspired by DAI. It uses Chainlink price feeds to maintain a $1 USD peg and enforces on-chain collateralization rules to ensure system solvency. Users can mint the stablecoin by depositing exogenous crypto collateral (wETH and wBTC), with minting and liquidation logic enforced algorithmically through smart contracts. The protocol demonstrates core DeFi concepts including price oracles, collateralized debt positions, mint/burn mechanics, and decentralized stability guarantees.

Architecture:
1. Relative Stability: Anchored or Pegged -> $1.00
    1. Chainlink Price Feed
    2. Set a function to exchange ETH & BTC -> $$$
2. Stability Mechanism (Minting): Algorithmic (Decentralized)
    1. People can only mint the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    1. wETH
    2. wBTC

- [Foundry DeFi Stablecoin](#foundry-defi-stablecoin)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Deploy](#deploy)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
- [Deploying to a local anvil chain](#Deploying-to-local-anvil-chain)
  - [Estimate gas](#estimate-gas)


# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`


## Quickstart

```
git clone https://github.com/LightPat/foundry-defi-stablecoin.git
cd foundry-defi-stablecoin
make
```

# Usage

## Deploy

```
forge script script/DeployDSC.s.sol
```

## Testing

```
forge test
```

or 

```
// Only run test functions matching the specified regex pattern.

"forge test -m testFunctionName" is deprecated. Please use 

forge test --match-test testFunctionName
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deploying to local anvil chain

```
make anvil
make deploy
```

# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

2. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

3. Deploy

```
forge script script/DeployDSC.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`