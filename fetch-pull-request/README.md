# プルリクの一覧を絞り込んでローカルに持ってくる
[この記事](http://qiita.com/yuku_t/items/f53a9d3ea92614b0927d)の補足記事になります  
今までプルリクを使った開発をしていなかったので放っておいたんだけど、読み直したらとても良いネタだったので展開するっぺよ

## Percol
+ 標準出力を渡すとインクリメンタルサーチが出来るツール
+ 絞り込んだ対象は次のコマンドの引数に出来る
 + 簡単なエイリアスで色々できる
 + 複数選択も出来る
+ 参考資料
 + [percolを使ってターミナル操作を早く、便利に。](http://d.hatena.ne.jp/sugyan/20140611/1402487717) 2014/06/11
 + [ライフチェンジングなpercolとautojumpの紹介](http://blog.zoncoen.net/blog/2014/01/14/percol-autojump-with-zsh/) 2014/01/14
 + 他たくさん

## prfetchの導入
ほぼ上記の記事通りで導入できる  
唯一直さなければならない点が、github-apiのurl変更? に追従していない点  
`owner/repo.git`という形のurlでapiを叩こうとしているが、`owner/repo`の形でなければならない

prfetchの16行目の下あたりにこんな感じで書けばおk
```Ruby
repo = repo.split(".")[0]
```

アクセストークンを使っての認証で会社のプライベートリポジトリでも問題なくアクセスできた

## おまけ
### pecoというのがあるらしい
+ [github](https://github.com/peco/peco)
+ 出来る事は同じっぽい
+ percolベースのgo-lang製のものらしい
+ percolはpythonベースで、設定ファイルもpythonで書けるので、どちらを使うかは好みでよさそう

### percol利用例
+ `alias gdfp="git status -s | percol --match-method regex | cut -c4- | xargs git diff"`
+ `alias gcop="git branch | percol --match-method regex | cut -c2- | xargs git checkout"`
+ `alias grvp="git fecth --prune > /dev/null 2>&1; git branch -r | percol --match-method regex | cut -c2- | xargs git checkout -B reviewing"`
+ ちょっとスクリプトを書いて「ファイル一覧を絞り込んでvi」とか「ディレクトリ一覧を絞り込んでcd」とかもしている

### 常にreviewingブランチに持ってくる
+ `alias gprp="prfetch | percol --match-method regex | cut -f3 | xargs -I{} git checkout -B reviewing origin/{} > /dev/null 2>&1"`

### プロキシ
+ Client.newの引数に文字列を渡せばおk
+ SSID次第で設定するのはこんな感じ
```Ruby
ssid = `/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I `
         .split("\n").select { |line| line.include?(" SSID") }[0].split(":")[1].strip()

proxy = ssid == "xxxWiFi" ? "http://xxx.xxx.xxx.xxx:port" : ""

Octokit::Client.new(netrc: true, proxy: proxy).pull_requests(repo).each do |pr|
```

### 他
+ Rubyの読み書きした事無いのでコードの質は気にしてない

## 結論
ホントにpercolは超便利  
これでレビューしやすいね
