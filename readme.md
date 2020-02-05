# Goのバージョン管理シェルスクリプト

Goのコンパイラごと
バージョンを切り替えたくなったことが何度かありました。
面倒になったのでコンパイラのインストールをshellscriptにしました。
原始的ですが割と高速にインストールできます_(:3 」∠ )_
これでwgetして自動インストールができるように(/'ω')/

スクリプトは長くなってしまったので [Github](https://github.com/xcd0/go_compiler_install/blob/master/go_compiler_install.sh) に置きました。
wgetやcurlでとる場合

```shell
wget https://raw.githubusercontent.com/xcd0/go_compiler_install/master/go_compiler_install.sh
```
で取れます。

使い方はそのままたたくとヘルプが表示されますのでそれに従ってください。
何も考えずただコマンド1つでインストールしたい場合は、

```shell
./go_compiler_install.sh -v go1.13.7 -d $HOME/work/go -f -p
```
のようにしてください。バーションなどは書き換えて使用してください。

まためちゃくちゃ丁寧なインタラクティブモードを用意しています。

```shell
./go_compiler_install.sh -i
```
を実行してください。

<details><summary>以下長い説明</summary><div>
## 推奨
gvmというのがあるらしいのでそちらをお勧めします
https://techte.co/2018/01/23/golang-gvm/

どうしても原始的に管理したい場合のみどうぞ

この記事の方法の一応の利点として、
gvmと比べるとインストールが早いです。
gvmはソースコードからビルドするためマシンパワーと処理時間が必要です。
私の方法ではビルド済みのものをダウンロードしてくるため時間短縮になります。

CPUが2014年発売のIntel(R) Celeron(R) CPU G1840 @ 2.80GHzである
非力な私のサーバーでgo1.13.4をインストールした場合、
下記のよく使うパッケージのインストールまで含めて

```
real    1m6.921s
user    0m10.417s
sys     0m3.201s
```
となりました。
(ただし回線速度は速いです。)

## 注意
宗教上の理由により、 私はプログラム関係のデータを
`$HOME/work`以下にディレクトリを掘って保存しています。
なのでGoのインストールも$HOME/work/go以下にすべて配置します。

`GO_INSTALL_DIR` という変数を2か所設定して使っています。
読み替える場合、これを書き換えてください。

## 説明

今回複数バージョンのコンパイラを管理するため、
ディレクトリが深くなっています\_(:3 」∠ )\_
`$GO_INSTALL_DIR` 以下にバージョンごとの環境を保存し、
使いたいバージョンのディレクトリに対して
`$GO_INSTALL_DIR/go` からシンボリックリンクを張ります。

最終的に以下のようになります。

```
$GO_INSTALL_DIR
├── go -> go1.13.3     <- これはシンボリックリンク
├── go1.12.12
│   ├── bin
│   ├── go             <- これがgo1.12.12のコンパイラ
│   ├── pkg
│   └── src
└── go1.13.3
    ├── bin
    ├── go             <- これがgo1.13.3のコンパイラ
    ├── pkg
    └── src
```

## 環境変数について

Goで使用される環境変数を設定します。

|変数名|説明|設定値|
|:---:|:---:|:---|
|GOPATH|作業ディレクトリ|$GO_INSTALL_DIR/go|
|GOBIN |バイナリが置かれる場所|$GO_INSTALL_DIR/go/bin|
|GOROOT|goのインストール場所|$GO_INSTALL_DIR/go/go|

`.bachrc` or `.bash_profile` などに下記を記述して環境変数を設定します。  

```sh
# 読み替える場合、これを書き換える
GO_INSTALL_DIR=$HOME/work/go

export GOPATH=$GO_INSTALL_DIR/go
export GOBIN=$GOPATH/bin
export GOROOT=$GOPATH/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
```

## Goのインストール

OSにかかわらず、$HOME/work/go/以下に、
バージョン名のディレクトリを掘ってインストールしています。

インストールには以下に記載するシェルスクリプトを使っています。
適当に保存してください。

インストール場所を読み替える場合は、

```sh
GO_INSTALL_DIR=$HOME/work/go
```

の部分書き換えてください。
</div></details>

以上です。やさしめのマサカリ待ってます\_(:3 」∠ )\_
