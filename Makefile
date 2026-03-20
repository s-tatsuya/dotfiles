.PHONY: help install apply update clean setup-docker

# --- ここから追加：OSとアーキテクチャによるターゲット自動判別 ---
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
    # Apple Silicon Mac (aarch64-darwin) または Intel Mac (x86_64-darwin)
    TARGET := mac
else ifeq ($(UNAME_S),Linux)
    # UbuntuなどのLinux (x86_64-linux)
    TARGET := ubuntu
else
    TARGET := default
endif
# --- ここまで追加 ---

help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## 新しい環境でNixをインストール
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

setup-homemanager: ## home-managerをインストールする
	nix run github:nix-community/home-manager -- init --switch

apply: ## 現在の設定を適用
	# 修正箇所：--flake .\#default を .\#$(TARGET) に変更
	home-manager switch --flake .\#$(TARGET) --impure

setup-docker: ## Dockerデーモンのインストールと権限設定 (公式スクリプトを使用)
	@echo "Installing Docker Engine using official script..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	rm get-docker.sh
	sudo systemctl enable docker
	sudo systemctl start docker
	@echo "Adding user to docker group..."
	sudo usermod -aG docker ${USER}
	@echo "Done! Please re-login or restart shell to apply group changes."

update: ## flake.lockを更新して適用
	nix flake update
	@$(MAKE) apply

clean: ## 古い世代を削除
	nix-collect-garbage -d