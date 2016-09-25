zshの補完を自作してFabricのタスクを補完する

[`fab`](http://fabric-ja.readthedocs.io/ja/latest/tutorial.html)してますか？[`fab`](http://fabric-ja.readthedocs.io/ja/latest/tutorial.html)！

例えば`fab task-name:'arg'`の形で実行すると思いますが、タスク名補完したいですよね？うん、したいはず！

## デモ
```
$ fab -l
===========
some header
===========
Available commands:

    fetch   (yyyymmdd = today)
    put
    search  (yyyymmdd, keyword)
```

`-l`でタスク名一覧と、書いてあればdocが表示されるので、これをごにょって補完出来る様にしたよ！

```
$ fab <TAB>
tasks
fetch                  -- (yyyymmdd = today)
search                 -- (yyyymmdd, keyword)
put
```

普通のコマンドと同じ様に、一意になるまで入力すれば自動で選ばれるし、Shiftで順次選択も当然出来るよ！
docもサブコマンド説明につっこんだよ！

```
$ fab -f no_doc.py -l
Available commands:

    fetch
    search

$ fab -f no_doc.py <TAB>
tasks
fetch   search
```

`-f`でデフォルト以外のfabfileを指定していてもちゃんと補完出来るよ！

```
$ fab -f <TAB>
fabric file
__init__.py   fabfile.py   no_doc.py
```

`-f`の補完はちゃんとファイルになるよ！

便利！！！！！

## 解説
結構勉強になったのでまじめに解説

参考にしたページを下部に記載し、細かい説明や他の方法の記載はある程度省略します
この手の資料は大量に既にあるので、詳しく知りたい場合はそちらを参照してください

### コマンドに対する補完関数を作成して割り当てる
```zsh
compdef _fab_tasks fab

function _fab_tasks {
    _values 'tasks' 'a' 'b' 'c'
}
```

+ この`xxx.zsh`ファイルを`source xxx.zsh`コマンドで読み込む
 + これ以降は段階を踏んで書き足していくので、再現してみたい場合は都度`source`を行うこと
+ `compdef 関数名 コマンド名`で任意のコマンドで`<TAB>`を押した時に呼び出す関数を設定できる
+ `_values 'グループ名' '候補' '候補' ...`で補完対象を追加できる
 + グループ名は`zstyle ':completion:*' format '%B%d%b'`の様に`zshrc`等で設定されていると表示される

```
$ fab <TAB>
tasks
a  b  c
```

### 補完対象の説明を追加する
```zsh
    _values 'tasks' 'a[do a]' 'b[delete b]' 'c[search c]'
```

`_values`で追加する要素に`[xxx]`を結合すると、それが補完対象の説明となる

```
$ fab <TAB>
tasks
a  -- do a
b  -- delete b
c  -- search c
```

これだけ知っていれば後はshellの工夫で候補を作れば良い

### オプション等の細かい挙動を決める
補完候補の追加はわかったので、今度は補完全体の挙動を設定する

```zsh
compdef _fab_complete fab

function _fab_tasks {
    _values 'tasks' 'a[do a]' 'b[delete b]' 'c[search c]'
}

function _fab_complete {
    _arguments \
        '*:tasks:_fab_tasks'
}
```

様々な設定や条件分岐には`_arguments`と言う関数を使う

これはいわばScalaやHaskellの`macth-case`の様なものだと解釈した
行毎に`パターン:グループ名（略可）:命令（略可）`の様な形で記述する

上記のコードだと全てにおいて(`*`)`_fab_tasks`を呼び出すので、最初に掲載した挙動とかわらない
（`compdef`は`_fab_complete`に変わった点に注意）

#### `-l`オプションを足す
```zsh
    _arguments \
        -l \
        '*:tasks:_fab_tasks'
```

これは上記で言う`パターン:略:略`の形で、この`-l \`の行だけで`fab`コマンドの補完可能なオプションに`-l`を増やすことが出来る
`fab -<TAB>`の様に`-`まで入力してあると（一意なので）自動で`-l`が補完される

ちなみに、一切設定を入れていない場合は`-`が入力されていてもファイル一覧を探そうとする（何故か何も見つからないけど）

```
$ fab -<TAB>
`file'
```

#### `-f`オプションを足す
流石に`-l \`だけじゃあ寂しいので、`-f`オプションも追加してみる

```zsh
    _arguments \
        -l \
        -f \
        '*:tasks:_fab_tasks'
```

```
$ fab -<TAB>
option
-f  -l
```

optionと言うグループ名で候補が選べる様になった
ここからもう少し改良を続けてみる

#### オプションにも説明を足す
なんとなくお察しかもしれないが、オプションも説明は`[xxx]`で設定することが出来る

```zsh
    _arguments \
        -l'[list]' \
        -f'[fabfile]' \
        '*:tasks:_fab_tasks'
```

```
$ fab -<TAB>
option
-f  -- fabfile
-l  -- list
```

#### `--list`と`--file`を足す
`-l`と`--list`どちらでも同じ挙動をする様にしてみる

```zsh
    _arguments \
        {-l,--list}'[list]' \
        {-f,--file}'[fabfile]' \
        '*:tasks:_fab_tasks'
```

```
$ fab -<TAB>
option
--file  -f  -- fabfile                                                                                                                                                                                    
--list  -l  -- list    
```

複数のオプションが同じ説明で並んでいるので良さそう

だが、実はちょっと残念な点がある
`-l`と`--list`の両方を重複して入力できてしまうのだ

```
$ fab -l -<TAB>
option
--file  -f  -- fabfile                                                                                                                                                                                    
--list      -- list                                                                                                                                                                                       

$ fab -l --file -<TAB>
option
--list  -- list
-f      -- fabfile
```

2度は指定しないよね

#### 排他制御をする
`パターン`の前に`'(x, y)'`の形で排他指定をすることが出来る

```zsh
    _arguments \
        '(- *)'{-l,--list}'[list]' \
        '(-f --file)'{-f,--file}'[fabfile]' \
        '*:tasks:_fab_tasks'
```

```
$ fab -<TAB>
option
--file  -f  -- fabfile                                                                                                                                                                                    
--list  -l  -- list                                                                                                                                                                                       
```

補完候補は今まで通りだけど

```
$ fab -f -<TAB>
option
--list  -l  -- list                                                                                                                                                                                       
```

`-f`が入力済みの場合は`--file`は候補にならない

また、`(- *)`の様にすることで、そのオプション以降は何も補完されなくすることも可能
今回の`--list`系のオプションや、ヘルプで有効だ

```
$ fab -l <TAB>
no more arguments

$ fab -f -l <TAB>
no more arguments
```

#### オプション毎に次に補完させたい候補を分ける
`パターン`に続く`グループ名（略可）:命令（略可）`の部分を記述すると、そのオプションの次の候補を任意に設定できる
`-f`には`_files`を設定してみよう

```zsh
    _arguments \
        '(- *)'{-l,--list}'[list]' \
        '(-f --file)'{-f,--file}'[fabfile]:fabric files:_files' \
        '*:tasks:_fab_tasks'
```

```
$ fab -f <TAB>
fabric files
__init__.py  fabfile.py  no_doc.py
```

グループ名が`fabric files`で候補がファイル一覧になっている
ちなみに他にも`_users`等もあるので、気になったら調べてみるとおもしろいかも

オプション等に関してはここまで

### `-f fabfile`に応じて補完候補を動的に切り換える
最後に少しだけ、fabricの話に戻ります

基本は`fab -l`の結果をパースすれば良いんだけど、一点だけどう実装するべきかわからないことがあって`BUFFER`という変数を使ってみた
困った点は`fab -l`と`fab -f another_fabfile.py -l`の結果が違う点で、
`BUFFER`という変数は現在のコマンドラインに入力されている行そのものが入っている

```zsh
    fabfile=`echo $BUFFER | awk '{for(i=1; i <= NF; i++) if($i == "-f") print $(i + 1) }'`

    if [ -n "$fabfile" ]; then list=`fab -f $fabfile --list`; else list=`fab --list`; fi
```

こんな感じで現在入力中の`-f`の状態によって`-l`の結果を動的に得ることにした
（`-f`の次が`another_fabfile.py`であることは、先述の「`-f`の次は`fabfile`を補完する」という設定である程度保証している）

## 完成形
```zsh
compdef _fab_complete fab
function _fab_tasks {
    in_header=1
    tasks=()
    IFS_BK=$IFS
    IFS=$'\n'

    fabfile=`echo $BUFFER | awk '{for(i=1; i <= NF; i++) if($i == "-f") print $(i + 1) }'`

    if [ -n "$fabfile" ]; then list=`fab -f $fabfile --list`; else list=`fab --list`; fi

    while read line
    do
        if [[ $line = '' ]] ;then
            continue
        fi
        if [[ $in_header -ne 1 ]] ;then
            tasks+=(`echo $line | awk '{printf("%s", $1); $1=""; if ($0 != "") printf("[%s]", $0)}' | sed -e 's/\[ /\[/g'`)
        fi
        if [[ $line =~ 'Available commands:' ]]; then
            in_header=0
        fi
    done <<END
$list
END

    _values 'tasks' $tasks
    IFS=$IFS_BK
}

function _fab_complete {
    _arguments \
        '(- *)'{-l,--list}'[print list of possible commands and exit]' \
        '(-f --file)'{-f,--file}"[python module file to import, e.g. '../other.py']:fabric file:_files" \
        '*:tasks:_fab_tasks'
}
```

shellを書き慣れていないので多分イケてないコードだろうし、すごい時間かかったけど、挙動と得た知識には大変満足している

## 参考資料
今回参考にしたページ
読んで得た知識を抜粋して箇条書きで掲載する

+ [zsh の補完関数の自作導入編](https://gist.github.com/mitukiii/4954559)
 + 諸設定
 + 補完関数の読込ルール等
 + 全体の流れ
+ [zsh補完関数を自作すると便利 - hakobe-blog](http://hakobe932.hatenablog.com/entry/2012/02/13/214934)
 + `compadd`の例
 + prefixを設定する例
+ [漢のzsh (18) コマンド補完設定 - daemonコマンド編(2) | マイナビニュース](http://news.mynavi.jp/column/zsh/018/)
 + `_arguments`の例
+ [zshのある暮らし2 - 補完ファイル](http://wiki.fdiary.net/zsh/?%CA%E4%B4%B0%A5%D5%A5%A1%A5%A4%A5%EB)
 + `_arguments`の排他の例
+ [ZSH - Writing own completion functions | Ask QL](https://askql.wordpress.com/2011/01/11/zsh-writing-own-completion/)
 + 補完しようとしているのがn番目かで挙動を変える例
