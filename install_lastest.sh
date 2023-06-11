#!/bin/bash

################################################################################
# コンパイラをインストールする基準ディレクトリ 任意
GO_INSTALL_DIR=$HOME/go
################################################################################

################################################################################
# インストールするコンパイラのバージョン go1.13.3のように頭にgoをつける
################################################################################

tmp=""
while getopts :v: OPT; do
	case $OPT in
		v) tmp="$OPTARG" ;;
		:);;
		?);;
	esac
done

if [ "$tmp" != "" ]; then
	# バージョン指定があった。
	# 書式はgo1.xx.xx
	# 書式が不正であってもここではチェックしない
	VERSION="$tmp"
else
	VERSION=$(

		# https://golang.org/dl/ を一旦テキストとして保存する
		# 別に保存する必要はないがデバッグ用
		if [ ! -e golang.org-dl-index.html ]; then
			chmod 660 ~/.wget-hsts 2> /dev/null
			wget -q -O golang.org-dl-index.html https://golang.org/dl/
			if [ $? -eq 4 ] || [ $? -eq 8 ]; then
				echo wget -q -O golang.org-dl-index.html https://golang.org/dl/
				echo "404が返されました。ネットワークの接続を確認してください。"
				rm golang.org-dl-index.html
			fi
		fi

		# index.htmlからdownloadBoxの部分だけ取り出す
		str=`cat golang.org-dl-index.html | grep downloadBox`
		# grepするとこんな感じになる
		# <a class="download downloadBox" href="/dl/go1.17.1.windows-amd64.msi">
		# <a class="download downloadBox" href="/dl/go1.17.1.darwin-amd64.pkg">
		# <a class="download downloadBox" href="/dl/go1.17.1.linux-amd64.tar.gz">
		# <a class="download downloadBox" href="/dl/go1.17.1.src.tar.gz">

		# awkで1行目の上の例でいうgo1.17.1の部分だけを切り出す
		echo $str | awk 'NR==1 {      # 1行目だけ処理する
			split($4, tmp, "/")       # 半角空白区切りで4列目のhrefで始まる部分を/区切りで分割してbに入れる tmp[3]が go1.17.1.windows-amd64.msi"> のようになる
			i=index(tmp[3], "w")      # tmp[3]の中で .windows-amd64.msi"> がいらないので 文字列の先頭からのwの位置を調べiに入れる
			v=substr(tmp[3], 1, i-2)  # tmp[3]の先頭からi-2までを切り出す (awkは1からカウントする)
			print v                   # 切り出した文字列を標準出力に出力する
		}'
	)
fi

echo lastest version is $VERSION

# もういらないので消す デバッグ時はこれ残したらよさそう
rm golang.org-dl-index.html

function envInit(){ #{{{
	OS=""
	ARCH="amd64"
	EXT="tar.gz"    # 拡張子
	DEC="tar xzvf"  # 伸張コマンド
	# OS判定して変数OSとEXTとDEC弄る
	if [ "$(uname)" == "Darwin" ]; then
		OS='darwin'
	elif [ "$(uname)" == "FreeBSD" ]; then
		OS='freebsd'
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		OS='linux'
		if [ "$(uname -m)" == "armv6l" ]; then
			ARCH="armv6l"
		fi
	elif [ "$(expr substr $(uname -s) 1 4)" == "MSYS" ] \
		|| [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
			OS='windows'
			# windowsだけ圧縮形式が違うので変数上書き
			EXT="zip"    # 拡張子
			DEC="unzip"  # 伸張コマンド
			if ! ( type "unzip" > /dev/null 2>&1 ); then
				echo "unzipコマンドが存在しません。pacman経由でインストールします。"
				echo pacman -S unzip --noconfirm
				pacman -S unzip --noconfirm
			fi
			if ! ( type "zip" > /dev/null 2>&1 ); then
				echo "zipコマンドが存在しません。pacman経由でインストールします。"
				echo pacman -S zip --noconfirm
				pacman -S zip --noconfirm
			fi
	fi
} #}}}

function preprocess(){ # {{{1
	# GOPATHのチェック
	if [ "$GOPATH" != "$GO_INSTALL_DIR/go" ]; then
		cat << EOS >> ~/.bashrc

# golang env
GO_INSTALL_DIR=$GO_INSTALL_DIR
EOS
cat << "EOS" >> ~/.bashrc
export GOPATH=$GO_INSTALL_DIR/go
export GOBIN=$GOPATH/bin
export GOROOT=$GOPATH/go
export PATH=$GOBIN:$GOROOT/bin:$PATH
EOS
	fi

	# 既存のgolangのチェック
	gover=`go version 2> /dev/null`
	gover="使用中のGoのコンパイラのバージョン : $gover"
	godst=`which go 2> /dev/null`
	gover="$gover : $godst"
	godst=`which go 2> /dev/null`
	if [ $? -eq 1 ]; then
		godst="not installed."
		gover=""
	fi

	cat << EOS
OS : $OS  Arch : $ARCH インストール先 : $GO_INSTALL_DIR
既存のコンパイラバージョン : $gover
インストールするバージョン : $VERSION
\$GOPATH : $GOPATH
EOS

} #}}}

# golangのコンパイラの圧縮ファイルをダウンロードして展開しパスを通す
# $GO_INSTALL_DIR, $VERSION, $ARCH, $EXT が設定されている必要がある
function goInstall(){ # {{{1
	# ディレクトリ構造の雰囲気はこんな感じ
	# $GO_INSTALL_DIR
	# |-- go -> go1.17.1  # シンボリックリンク
	# |-- go1.16.5        # 別バージョン
	# |   |-- bin
	# |   |-- go
	# |   |-- pkg
	# |   `-- src
	# `-- go1.17.1        # 実際に使うバージョン
	#     |-- bin
	#     |-- go
	#     |-- pkg
	#     `-- src
	mkdir -p $GO_INSTALL_DIR 2> /dev/null     # インストール先が存在しなれば作成する
	cd $GO_INSTALL_DIR; if [ $? -ne 0 ]; then # $GO_INSTALL_DIRに移動できなかった
		echo "エラー : $GO_INSTALL_DIR に移動できません。"; echo "終了します。"; exit 1
	fi
	if [ -e ${GO_INSTALL_DIR}/${VERSION} ]; then # インストール済みかどうか調べる
		echo "注意 : ${GO_INSTALL_DIR}/${VERSION}が存在します。"
		echo "既存のコンパイラ再度インストールしたい場合先に削除してください。"
		echo "$VERSION のインストール処理を中止します。"; return 1
	fi
	mkdir $GO_INSTALL_DIR/$VERSION; cd $GO_INSTALL_DIR/$VERSION # バージョン名のフォルダ作成&入る

	# ダウンロード & 伸張
	echo wget https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}
	if aria2; then
		aria2 -x15 -s10 https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}  https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}
	else
		wget https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}
	fi
	#echo aria2c -x 16 https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}
	#aria2c -x 16 https://dl.google.com/go/${VERSION}.${OS}-${ARCH}.${EXT}

	${DEC} ${VERSION}.${OS}-${ARCH}.${EXT}
	rm ${VERSION}.${OS}-${ARCH}.${EXT}
	# シンボリックリンクを張る
	cd $GO_INSTALL_DIR; rm -rf go; ln -s ${VERSION} go

	if !(type "go" > /dev/null 2>&1); then
		export PATH=$GOBIN:$GOROOT/bin:$PATH
	fi
	go version

} # }}}1

function postProcess(){
	echo "Golangでよく使われるパッケージをインストールしますか？"
	echo "これは時間がかかるのでバックグラウンドで実行します。"
	echo "今実行せずとも./useful_package.shを実行すればインストールできます。"
	read -n1 -p "よく使うパッケージをインストールしますか? (y/N): " yn
	[[ $yn = [yY] ]] \
		&& bash ./useful_package.sh > /dev/null 2>&1 \
		& echo 1分程度かかるためバックグラウンドでインストールしています。 \
		|| echo "よく使うパッケージをインストールしませんでした。 ./useful_package.sh からインストールできます。"
}

envInit
preprocess
goInstall
#postProcess

echo ${VERSION}のインストールが完了しました。
echo 環境変数の読み込みのためにシェルを再起動してください。
