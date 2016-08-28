vimプラグインを作る

1. gitの準備
 + gitのリポジトリを作る
 + ローカルに開発ディレクトリを作ってgit initする
+ とりあえず書く
 + main.vimにベタ書きして、so main.vimをした
+ マニュアルを読む
 + tab h write-plugin@ja
+ ヘッダ書いてみた
 + [参考](https://github.com/Shougo/unite.vim/blob/master/plugin/unite.vim)
 ```
 " Maintainer: Suzuki Hoge <https://github.com/suzuki-hoge/cursor-correct>
 " License:    This file is placed in the public domain.
 ```
+ docを書いてみる
 + tab h add-local-help
 + :!cp $VIMRUNTIME/macros/matchit.txt ~/.vim/doc
 + :helptags ~/.vim/doc
 + tab h g%
 + :help　local-additions
+ 書いてみた！
 + local-addtions
 + tag-jump




1行目はlocal-additionsというのに足されるらしい
→ tab h local-addistion
`*`で囲むとタグジャンプが出来る様になる
また、ヘルプの別の項目を参照する場合は`|`で囲む


+ shell?help-tab?
+ 公開する
+ プラグイン元ネタ -> qiitaへのリンク





+ ユーザが定義していない時だけ定義する方法
+ `<Leader>`を使う方法
+ `<Plug>`
+ `<SID>`
+ `<unique>`
+ コマンドを定義していない時だけ
