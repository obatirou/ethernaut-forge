.PHONY: test

all: clean upgrade yarn-install husky-install build test snapshot format

clean  :; forge clean

upgrade :; foundryup

yarn-install :; yarn install

husky-install :; npx husky install

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt