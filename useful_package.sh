#!/bin/bash

go install github.com/akavel/rsrc@latest  &
go install github.com/go-bindata/go-bindata@latest  &
go install github.com/google/go-github/github@latest  &
go install github.com/jteeuwen/go-bindata/...@latest  &
go install github.com/k0kubun/pp@latest  &
go install github.com/mdempsky/gocode@latest  &
go install github.com/monochromegane/go-bincode/...@latest  &
go install github.com/rogpeppe/godef@latest  &
go install github.com/russross/blackfriday@latest  &
go install github.com/shurcooL/github_flavored_markdown@latest  &
go install github.com/tdewolff/minify/css@latest  &
go install github.com/x-motemen/ghq@latest  &
go install github.com/x-motemen/gore/cmd/gore@latest &
go install golang.org/x/lint/golint@latest  &
go install golang.org/x/tools/cmd/...@latest  &
go install golang.org/x/tools/cmd/goimports@latest  &
go install golang.org/x/tools/gopls@latest &
go install github.com/peco/peco/cmd/peco@latest

wait
git config --global ghq.root $GOPATH/src
