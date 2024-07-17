# TOL Contract

TOL Contract is an open-source project that serves as the core smart contract for the TOL (Token Offering Launchpad) project, designed to facilitate decentralized application (DApp) launches. This project utilizes the Hardhat framework and is written in Solidity.

## Prerequisites

Before you begin, ensure you have met the following requirements:

-  Node.js and npm installed
-  Hardhat installed globally (`npm install --global hardhat`)
-  A development environment set up for Solidity

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/your-username/tol-contract.git
   ```
2. Navigate to the project directory:
   ```sh
   cd tol-contract
   ```
3. Install the dependencies:
   ```sh
   npm install
   ```

## Usage

### Compiling the Contracts

To compile the smart contracts, run:

```sh
npx hardhat compile
```

### Deploying the Contracts

To deploy the contracts, create a deployment script in the `scripts` directory and run:

```sh
npx hardhat run scripts/deploy.js
```

## Testing

To run the tests, use:

```sh
npx hardhat test
```

## Contributing

Contributions are welcome! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Make your changes.
4. Commit your changes (`git commit -m 'Add some feature'`).
5. Push to the branch (`git push origin feature/your-feature`).
6. Create a Pull Request.

Please ensure your code follows the project's coding standards and includes tests for any new features or bug fixes.

## License

This project is licensed under the GPL 3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

-  [Hardhat](https://hardhat.org/) - Development environment for Ethereum.
-  [Solidity](https://soliditylang.org/) - The programming language for Ethereum smart contracts.
