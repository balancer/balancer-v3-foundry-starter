# Balancer Foundry Starter Kit

Example foundry scripts for interacting with Balancer v3

1. Ensure you have the latest version of foundry installed

```
foundryup
```

2. Clone repo and install dependencies

```
git clone https://github.com/balancer/balancer-v3-foundry-starter.git
cd bbalancer-v3-foundry-starter/
forge install
```

3. Create a `.env` file in the root of the project and add any necessary environment variables

```
cp .env.example .env
```

4. Simulate a script

```
forge script script/GyroResolvECLPCreate.s.sol:GyroResolvECLPCreate --rpc-url mainnet
```

5. Broadcast a script

```
forge script script/GyroResolvECLPCreate.s.sol:GyroResolvECLPCreate --rpc-url mainnet --broadcast
```
