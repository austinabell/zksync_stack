OS := $(shell uname -s)
export ZKSYNC_HOME = $(shell pwd)/zksync-era

deps:
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	. $(HOME)/.nvm/nvm.sh; \
	nvm install 18.0.0; \
	nvm use 18.0.0; \
	npm i -g npm@9; \
	npm install --global yarn; \
	yarn policies set-version 1.22.19
	@if [ "$(OS)" = "Darwin" ]; then \
		brew install axel openssl postgresql tmux; \
		curl -L https://desktop.docker.com/mac/main/$(shell uname -m)/Docker.dmg --output Docker.dmg; \
	else \
		sudo apt update; \
		sudo apt install -y axel libssl-dev postgresql tmux git build-essential pkg-config cmake clang lldb lld; \
		curl -fsSL https://get.docker.com | sh; \
		curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose; \
		chmod a+x /usr/local/bin/docker-compose; \
	fi
	@if [ ! -n "$(shell which cargo)" ]; then \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
	fi
	. $(HOME)/.cargo/env; \
	cargo install sqlx-cli --version 0.5.13
	git clone https://github.com/matter-labs/zksync-era

run:
	cd ${ZKSYNC_HOME}; \
	./bin/zk; \
	./bin/zk init; \
	tmux new -d -s zksync-server "./bin/zk server"

