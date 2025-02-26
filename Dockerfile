FROM ubuntu:latest

ENV DAEMON_NAME=imuad \
HOME=/app \
DAEMON_HOME=/app/.imuad \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true \
MONIKER="Stake Shark" \
GO_VER="1.23.1" \
PATH="/app/.foundry/bin:/usr/local/go/bin:/app/go/bin:${PATH}" \
seeds="5dfa2ddc4ce3535ef98470ffe108e6e12edd1955@seed2t.exocore-restaking.com:26656,4cc9c970fe52be4568942693ecfc2ee2cdb63d44@seed1t.exocore-restaking.com:26656" \
HOMEDIR="/app/.imuad" \
CHAIN_ID="imuachaintestnet_233-8" \
VERSION="1.1.0"

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install jq build-essential curl git wget lz4 time bash -y && \
    curl -L https://foundry.paradigm.xyz | bash

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
    rm "go$GO_VER.linux-amd64.tar.gz" && \
    mkdir -p /app/go/bin /app/.imuad/cosmovisor/upgrades /app/.imuad/cosmovisor/genesis/bin

RUN wget -O imuad_${VERSION}.tar.gz "https://github.com/imua-xyz/imuachain/releases/download/v1.1.0/imuachain_1.1.0_Linux_amd64.tar.gz" && \
    tar -xvzf imuad_${VERSION}.tar.gz && \
    mv bin/imuad /app/.imuad/cosmovisor/genesis/bin/imuad && \
    rm imuad_${VERSION}.tar.gz CHANGELOG.md README.md

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN /app/.imuad/cosmovisor/genesis/bin/imuad --home $HOMEDIR init "Stake Shark" --chain-id $CHAIN_ID && \
/app/.imuad/cosmovisor/genesis/bin/imuad --home $HOMEDIR config chain-id $CHAIN_ID && \
sed -i.bak -e "s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):10656\"%" /app/.imuad/config/config.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" /app/.imuad/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" /app/.imuad/config/config.toml && \
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0001hua"|g' /app/.imuad/config/app.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.imuad/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' /app/.imuad/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" /app/.imuad/config/app.toml && \
sed -i -e "s/^keep-recent *=.*/keep-recent = \"1000\"/" /app/.imuad/config/app.toml && \
sed -i -e "s/^interval *=.*/interval = \"10\"/" /app/.imuad/config/app.toml && \
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" $HOME/.imuad/config/config.toml


ENTRYPOINT ["/app/entrypoint.sh"]
