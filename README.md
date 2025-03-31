# Abeg - Decentralized Crowdfunding Platform

Abeg is a decentralized crowdfunding platform built on the Stacks blockchain using Clarity smart contracts. It allows users to create fundraising campaigns and receive contributions directly in STX tokens without intermediaries.

## Features

- **Create Campaigns**: Anyone can create a fundraising campaign with a title, description, goal amount, and duration.
- **Contribute to Campaigns**: Support campaigns by contributing STX tokens.
- **Goal-Based Funding**: Campaigns must reach their funding goal to access the funds.
- **Automatic Refunds**: If a campaign doesn't reach its goal by the deadline, contributors can claim refunds.
- **Transparent and Secure**: All transactions are recorded on the blockchain, ensuring transparency and security.

## Smart Contract Functions

### Campaign Creation and Management

- `create-campaign`: Create a new crowdfunding campaign
- `claim-funds`: Campaign creators can claim funds after deadline if goal is reached
- `refund`: Contributors can claim refunds if campaign fails to reach its goal

### Contribution

- `contribute`: Send STX tokens to support a campaign

### Read-Only Functions

- `get-campaign`: Get details about a specific campaign
- `get-contribution`: Get the contribution amount made by a specific address
- `get-campaign-count`: Get the total number of campaigns created
- `get-campaign-status`: Check if a campaign is active, successful, or failed

## How It Works

1. **Creating a Campaign**:
   - A campaign creator calls `create-campaign` with details about their fundraising goal
   - The contract generates a unique campaign ID and stores the campaign details

2. **Contributing to a Campaign**:
   - Contributors call `contribute` with the campaign ID and the amount they wish to donate
   - The contract transfers STX from the contributor to the contract address
   - The contribution is recorded and the campaign's current amount is updated

3. **Campaign Completion**:
   - When the deadline is reached, the campaign is considered complete
   - If the goal amount was reached, the creator can call `claim-funds` to receive the contributions
   - If the goal amount was not reached, contributors can call `refund` to get their money back

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: User is not authorized to perform this action
- `ERR-CAMPAIGN-NOT-FOUND (u101)`: Campaign with the specified ID does not exist
- `ERR-CAMPAIGN-EXPIRED (u102)`: Campaign has already ended
- `ERR-CAMPAIGN-GOAL-REACHED (u103)`: Campaign has already reached its goal
- `ERR-INSUFFICIENT-FUNDS (u104)`: User does not have sufficient funds
- `ERR-ALREADY-CLAIMED (u105)`: Campaign funds have already been claimed
- `ERR-GOAL-NOT-REACHED (u106)`: Campaign did not reach its fundraising goal
- `ERR-CAMPAIGN-ACTIVE (u107)`: Campaign is still active
- `ERR-INVALID-PARAMS (u108)`: Invalid parameters provided

## Implementation Notes

- The contract uses STX as the native token for contributions
- Campaign durations are specified in blocks (roughly 10 minutes per block)
- All funds are held by the contract until either claimed by the creator or refunded to contributors
- The contract maintains maps for campaigns and contributions to track all activity

## Example Usage

### Creating a Campaign

```clarity
(contract-call? .abeg create-campaign "Help Fund My Project" "I need funds to build a community garden" u1000000000 u1440)
```
This creates a campaign with a goal of 1,000 STX and a duration of approximately 10 days.

### Contributing to a Campaign

```clarity
(contract-call? .abeg contribute u0 u50000000)
```
This contributes 50 STX to campaign #0.

### Claiming Funds (for Campaign Creators)

```clarity
(contract-call? .abeg claim-funds u0)
```
This allows the campaign creator to claim the funds if the goal was reached and the deadline has passed.

### Requesting a Refund (for Contributors)

```clarity
(contract-call? .abeg refund u0)
```
This allows a contributor to get a refund if the campaign failed to reach its goal.

## Security Considerations

- The contract ensures that only the campaign creator can claim funds
- Contributors can only get refunds if the campaign fails to reach its goal
- The contract prevents double-claiming of funds
- All critical operations include multiple checks to prevent abuse

## Future Improvements

- Add support for campaign updates and stretch goals
- Implement a fee mechanism to sustain the platform
- Add support for campaign categories and discovery features
- Implement milestone-based funding release
- Add ability to cancel campaigns under certain conditions

## License

This project is licensed under the MIT License.