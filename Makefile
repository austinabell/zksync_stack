OS := $(shell uname -s)
export ZKSYNC_HOME=$(shell pwd)/zksync-era

deps:
	@if [ "$(OS)" = "Darwin" ]; then \
		brew install axel openssl postgresql tmux nvm; \
		nvm install 18
		curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose; \
		curl -L https://github.com/matter-labs/zksolc-bin/releases/download/v1.3.16/zksolc-macosx-arm64-v1.3.16 --output zksolc; \
		chmod a+x zksolc; \
		curl -L https://github.com/ethereum/solidity/releases/download/v0.8.19/solc-macos --output solc; \
		chmod a+x solc; \
		mkdir -p $(HOME)/Library/Application\ Support/eth-compilers; \
		mv solc $(HOME)/Library/Application\ Support/eth-compilers; \
		mv zksolc $(HOME)/Library/Application\ Support/eth-compilers; \
	else \
		curl -s https://raw.githubusercontent.com/nodesource/distributions/master/scripts/nsolid_setup_deb.sh | sh -s "18"; \
		sudo apt update; \
		sudo apt install -y axel libssl-dev nsolid postgresql tmux git build-essential pkg-config cmake clang lldb lld; \
		curl -fsSL https://get.docker.com | sh; \
		curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose; \
		curl -L https://github.com/matter-labs/zksolc-bin/releases/download/v1.3.16/zksolc-linux-amd64-musl-v1.3.16 --output zksolc; \
		curl -L https://github.com/ethereum/solidity/releases/download/v0.8.19/solc-static-linux --output solc; \
		chmod a+x solc; \
		chmod a+x /usr/local/bin/docker-compose; \
		chmod a+x zksolc; \
		mkdir -p $(HOME)/.config; \
		mv solc $(HOME)/.config; \
		mv zksolc $(HOME)/.config; \
	fi
	@if [ ! -n "$(shell which cargo)" ]; then \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
	fi
	. $(HOME)/.cargo/env; \
	cargo install sqlx-cli --version 0.5.13;
	@if [ "$(OS)" = "Linux" ]; then \
		sudo service postgresql stop; \
	fi
	rm -rf zksync-era; \
	git clone -b boojum-integration https://github.com/matter-labs/zksync-era; \
	rm -rf block-explorer;
	git clone https://github.com/matter-labs/block-explorer; \
	cd ${ZKSYNC_HOME}; \
	npm i -g npm@9; \
	npm install --global yarn; \
	yarn policies set-version 1.22.19; \
	. $(HOME)/.cargo/env; \
	./bin/zk; \
	./bin/zk init

run:
	@if [ "$(OS)" = "Darwin" ]; then \
		. $(HOME)/.nvm/nvm.sh; \
		nvm use 18; \
	fi
	. $(HOME)/.cargo/env; \
	tmux kill-session -t zksync-server; \
	tmux new -d -s zksync-server; \
	tmux send-keys -t zksync-server "cd ${ZKSYNC_HOME}" Enter; \
	tmux send-keys -t zksync-server "./bin/zk up" Enter; \
	tmux send-keys -t zksync-server "./bin/zk server" Enter; \
	docker-compose up -d; \
	tmux kill-session -t zksync-explorer; \
	tmux new -d -s zksync-explorer; \
	tmux send-keys -t zksync-explorer "cd block-explorer" Enter; \
	tmux send-keys -t zksync-explorer "npm install" Enter; \
	tmux send-keys -t zksync-explorer "echo dev | npm run hyperchain:configure" Enter; \
	tmux send-keys -t zksync-explorer "npm run db:create" Enter; \
	tmux send-keys -t zksync-explorer "npm run dev" Enter; \
	tmux a -t zksync-explorer

