# sBTC Liquidity Aggregator

## Overview

The sBTC Liquidity Aggregator is a smart contract protocol that solves the problem of fragmented liquidity for sBTC across the Stacks ecosystem. As sBTC adoption grows, liquidity will be scattered across multiple DeFi protocols, making it inefficient for users to find the best rates and causing capital inefficiency. This project addresses that challenge by:

1. **Aggregating Liquidity Sources** - Providing a single entry point to access all sBTC liquidity across the ecosystem
2. **Optimized Routing** - Intelligently directing transactions to the most efficient liquidity source
3. **Flash Loans** - Enabling collateral-free borrowing within the same transaction
4. **Protocol Interoperability** - Creating standardized interfaces for various DeFi protocols to integrate

## Why This Matters for sBTC

sBTC represents a major advancement for Bitcoin by making it programmable while maintaining its security and decentralization. However, its utility will be limited if liquidity is fragmented across many small pools. This liquidity aggregator will:

- **Accelerate Adoption** - Make it easier for users to utilize sBTC in DeFi applications
- **Improve Capital Efficiency** - Allow smaller liquidity pools to function as one large pool
- **Enable Complex Financial Operations** - Support advanced DeFi strategies through flash loans
- **Create Network Effects** - As more protocols integrate, the aggregator becomes more valuable

## Architecture

The system consists of four core contract components:

### 1. Liquidity Registry (`liquidity-registry_clar.clar`)

This contract serves as the central registry of all liquidity sources in the ecosystem:

- Tracks available liquidity for each source
- Maintains adapter information for each protocol
- Provides optimal routing information
- Allows dynamic registration of new liquidity sources

### 2. Flash Loan Vault (`flash-loan-vault_clar.clar`)

This contract manages the flash loan functionality:

- Allows borrowing of sBTC without collateral within a single transaction
- Ensures all borrowed funds are returned with a fee
- Provides security measures to prevent abuse
- Collects and distributes fees

### 3. Liquidity Router (`liquidity-router_clar.clar`)

This contract handles the routing logic:

- Finds optimal paths for swaps and liquidity provision
- Handles slippage protection
- Executes transactions across multiple protocols if needed
- Integrates with flash loans for complex operations

### 4. Protocol Adapters (`amm-adapter_clar.clar`, `lending-adapter_clar.clar`)

These contracts standardize interactions with various protocols:

- Convert between different protocol interfaces
- Report liquidity metrics back to the registry
- Execute protocol-specific operations
- Handle protocol-specific error cases

## Smart Contract Details

### Liquidity Registry

```clarity
;; Key functions:
;; - register-liquidity-source: Register a new liquidity source in the system
;; - update-liquidity-metrics: Update available liquidity for a source
;; - get-optimal-source: Find the best source for a specific amount
;; - get-liquidity-source: Get details for a specific source
```

The registry maintains:
- Mapping of principal addresses to protocol information
- Available liquidity for each source
- Protocol type identifiers
- Active source status

### Flash Loan Vault

```clarity
;; Key functions:
;; - execute-flash-loan: Lend sBTC to a borrower for one transaction
;; - repay-flash-loan: Called by borrowers to repay loans
;; - set-flash-loan-fee: Administrative function to adjust fees
;; - withdraw-fees: Collect accumulated fees
```

The flash loan vault includes:
- Loan tracking system
- Fee calculation mechanism
- Security constraints for repayment
- Circuit breakers for emergencies

### Liquidity Router

```clarity
;; Key functions:
;; - swap-optimal: Execute a swap through the optimal source
;; - get-quote: Get the expected output for a swap
;; - execute-flash-loan-swap: Combine flash loans with swaps
;; - set-max-slippage: Set maximum allowed slippage
```

The router provides:
- Optimal path finding
- Slippage protection
- Multi-hop transaction support
- Integration with flash loans

### Protocol Adapters

```clarity
;; AMM Adapter key functions:
;; - initialize: Set up the adapter for a specific AMM
;; - execute-swap: Execute a swap through the AMM
;; - get-available-liquidity: Report current liquidity levels

;; Lending Adapter key functions:
;; - initialize: Set up the adapter for a lending protocol
;; - deposit-sBTC: Deposit sBTC into the lending protocol
;; - withdraw-sBTC: Withdraw sBTC from the lending protocol
```

The adapters standardize:
- Liquidity reporting
- Transaction execution
- Fee handling
- Error management

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed (version 1.0.0 or later)
- Basic understanding of Clarity and Stacks
- Node.js and NPM (for testing)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/sbtc-liquidity-aggregator.git
cd sbtc-liquidity-aggregator
```

2. Set up the development environment
```bash
clarinet integrate
```

### Deployment

This project is designed to interact with the sBTC contracts. To deploy for testing:

1. Deploy the contracts in the correct order
```bash
clarinet contract:deploy contracts/liquidity-registry_clar.clar
clarinet contract:deploy contracts/flash-loan-vault_clar.clar
clarinet contract:deploy contracts/liquidity-router_clar.clar
clarinet contract:deploy contracts/amm-adapter_clar.clar
clarinet contract:deploy contracts/lending-adapter_clar.clar
```

2. Initialize the adapters with mock protocols for testing

### Testing

The project includes Clarinet tests to verify functionality:

```bash
clarinet test
```

## Usage Examples

### Finding the Best Liquidity Source

```clarity
;; Query the router for the best source for 1000 sBTC
(contract-call? .liquidity-router_clar get-quote u1000)
```

### Executing an Optimal Swap

```clarity
;; Swap 1000 sBTC with 0.5% maximum slippage
;; Parameters: amount-in, min-amount-out, recipient
(contract-call? .liquidity-router_clar swap-optimal u1000 u995 tx-sender)
```

### Using a Flash Loan

```clarity
;; Borrow 5000 sBTC, swap 1000, and return the rest
;; Parameters: loan-amount, swap-amount, min-amount-out, recipient
(contract-call? .liquidity-router_clar execute-flash-loan-swap u5000 u1000 u995 tx-sender)
```

## Roadmap

### Phase 1: Core Infrastructure (Current)
- Basic liquidity aggregation
- Flash loan mechanism
- Simplified protocol adapters

### Phase 2: Enhanced Features
- Multi-hop routing for better rates
- Concentrated liquidity position handling
- Advanced analytics and price impact calculations

### Phase 3: Ecosystem Integration
- Support for major lending protocols
- Governance mechanism for parameter adjustments
- Advanced security features

## Security Considerations

The current implementation is a prototype designed for a hackathon. For production use, several security enhancements would be needed:

- **Formal Verification**: Contract logic should be formally verified
- **Audit**: Professional security audit of all contracts
- **Rate Limiting**: Mechanisms to prevent flash loan attacks
- **Circuit Breakers**: Emergency pause functionality for all critical operations
- **Slippage Protection**: More sophisticated slippage and price impact calculations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue for discussion.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [sBTC Documentation](https://docs.stacks.co/stacks-101/sbtc) - For background on the sBTC system
- [Clarity Language Reference](https://docs.stacks.co/clarity/documentation) - For Clarity programming resources
- Hiro Hack 2024 - For the opportunity to build on this exciting technology

## Contact

Your Name - [@yourtwitterhandle](https://twitter.com/yourtwitterhandle) - email@example.com

Project Link: [https://github.com/yourusername/sbtc-liquidity-aggregator](https://github.com/yourusername/sbtc-liquidity-aggregator)