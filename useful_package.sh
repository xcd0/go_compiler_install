#!/bin/bash

function with_ghg(){ # go installでインストールすると問題があるものをghgでインストール
	go install github.com/Songmu/ghg/cmd/ghg@latest
	export PATH="$HOME/.ghg/bin:$PATH"
	echo 'export PATH="$HOME/.ghg/bin:$PATH"' >> ~/.bashrc
	ghg get x-motemen/ghq
	ghg get dominikh/go-tools
	ghg get junegunn/fzf
	ghg get peco/peco
	ghg get cli/cli
}

with_ghg &

go install golang.org/x/tools/cmd/...@latest  &

go install github.com/x-motemen/gore/cmd/gore@latest &
go install github.com/k0kubun/pp@latest &

go install github.com/nametake/golangci-lint-langserver@latest &
go install github.com/akavel/rsrc@latest  &
#go install github.com/go-bindata/go-bindata@latest  &
#go install github.com/jteeuwen/go-bindata/...@latest  &
#go install github.com/monochromegane/go-bincode/...@latest  &
go install github.com/stamblerre/gocode@latest  &
go install github.com/rogpeppe/godef@latest  &

#go install github.com/russross/blackfriday@latest  &
#go install github.com/shurcooL/github_flavored_markdown@latest  &
#go install github.com/tdewolff/minify/css@latest  &


wait


git config --global ghq.root $GOPATH/src

if !(type "curl" > /dev/null 2>&1); then
	until sudo apt update; do sleep 1; done
	until sudo apt install curl -y --fix-missing; do sleep 1; done
fi
if !(type "golangci-lint" > /dev/null 2>&1); then
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
		| sh -s -- -b $(go env GOPATH)/bin 
	golangci-lint --version
fi

