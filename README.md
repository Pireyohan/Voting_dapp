# Voting_dapp
Installation
First you need to clone the project

git clone git@github.com:Pireyohan/Voting_dapp.git


Dependencies
In order to install all dependencies (ganache, truffle ...), please do like the following

npm install

// To install truffle globaly
npm install -g truffle

// To install ganache globaly
npm install -g ganache-cli
Tests

To run the project tests suite, do the following

// Run ganache localy
ganache-cli -h 127.0.0.1

// Run migrations
truffle migrate

// Launch test suite
truffle test
41 tests passing
Every functions are tested
95% coverage
