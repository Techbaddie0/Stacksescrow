# TrustBridge: P2P Trading Escrow Smart Contract

A decentralized escrow system for peer-to-peer trading built on Stacks blockchain.

## Features

- Secure escrow for P2P trading
- Dispute resolution system
- Configurable escrow fees
- Trade status tracking
- Automated fund transfers
- Role-based access control

## Contract Functions

### Trade Management
- `create-trade`: Create new trade with buyer and amount
- `confirm-delivery`: Confirm receipt and release funds
- `cancel-trade`: Cancel pending trade (seller only)

### Dispute Resolution
- `raise-dispute`: File dispute against trade (buyer only)
- `resolve-dispute`: Resolve dispute and allocate funds (arbitrator only)

### Administrative
- `set-escrow-fee`: Update escrow fee percentage
- `set-fee-collector`: Set fee collector address
- `set-arbitrator`: Assign arbitrator role
- `withdraw-fees`: Withdraw collected fees

## Error Codes

- u100: Owner only operation
- u101: Not authorized
- u102: Already exists
- u103: Trade not found
- u104: Invalid state
- u105: Unauthorized
- u106: Invalid amount
- u107: Invalid fee percentage
- u108: Invalid buyer
- u109: Invalid description
- u110: Invalid collector
- u111: Invalid arbitrator

## Status Types

- "pending": Trade in progress
- "completed": Trade completed successfully
- "cancelled": Trade cancelled by seller
- "disputed": Trade under dispute resolution

## Usage

1. Deploy contract
2. Set escrow fee and arbitrator
3. Create trade with buyer details
4. Complete trade flow or resolve disputes

## Security Features

- Role-based access control
- State validation checks
- Secure fund transfers
- Arbitration system
- Protected admin functions
