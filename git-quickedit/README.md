よく使うファイルをすぐ編集できるGitプラグインを作ってみた

普段よくやっていることをちょっとしたエイリアスにしていたんだけど、Gitプラグインを作って公開してみたくなったのでやってみた
ちょっと汎用化が足りないので、需要があるかは謎

## 概要
git管理下でよく編集するファイルをリストアップしておき、そのリストを[`percol`](https://github.com/mooz/percol)で絞り込みサクっと編集する
git管理下であればどこで実行しても正しいファイルパスで編集できる

## 動作環境
pythonは2.7で動作を確認した
3系での動作は未確認

## インストール
### git-quickedit
```
wget 'https://raw.githubusercontent.com/suzuki-hoge/dev-note/master/git-quickedit/git-quickedit'
```

上記の方法等で取得したファイルをパスの通った場所に置いてください
`git-xxx`という実行ファイルをパスの通った場所に置くと、`git xxx`で実行できます

### percol
```
sudo pip install percol
```

pipを用いない方法は[公式](https://github.com/mooz/percol#installation)を参照してください

## パスリスト
よく使うファイル名をテキストで管理します

### パス
特に明記が無い場合は`~/.git_quickedit`と言うファイルを用います

リポジトリ毎に変更したい場合は以下の様に`.git/config`に追記してください

```
git config quickedit.pathlist /Users/xxx/project-xxx/Dropbox/.git_quickedit
```

リポジトリ毎ではなくグローバルなパスリストを設定する場合は以下の様に`~/.gitconfig`に追記してください

```
git config --global quickedit.pathlist /Users/xxx/Dropbox/.git_quickedit
```

パスリスト検索は以下の順で行われます

1. リポジトリ固有の`.git/config`の設定場所
+ グローバルの`~/.gitconfig`の設定場所
+ `~/.git_quickedit`

また、指定されたパスに実ファイルが見つからなかった場合は新規作成を促すガイドが表示されます

### 内容例
```
.github/ISSUE_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE.md
.github/CONTRIBUTING.md
.git/config
.gitignore
README.md
```

僕はgithubのルールに則ったテンプレートファイルや良く触るファイルを定義しました
他には`.git/hooks/pre-push`なんてフックスクリプトとかを列挙しておいても良いかもしれません

## コマンド
### git template help
ヘルプを表示する

![help.png](https://qiita-image-store.s3.amazonaws.com/0/113398/9c2633f9-7b53-e3ae-a9ad-dc5617c62538.png)

### git template list
パスリストの参照をする

![list.png](https://qiita-image-store.s3.amazonaws.com/0/113398/e00b31d7-e90d-381a-ecfa-aa7458ebed59.png)

### git template manage
パスリストの編集をする

![manage.png](https://qiita-image-store.s3.amazonaws.com/0/113398/f2a7ee90-9f96-226a-827e-fad4f76ddeb8.png)

### git template new
リストの中の**実在しないパスのみ**を`percol`で選択し、`vim`で編集する

![new01.png](https://qiita-image-store.s3.amazonaws.com/0/113398/28579cbf-21aa-1612-c9da-bff058c63657.png)
![new02.png](https://qiita-image-store.s3.amazonaws.com/0/113398/f11b6515-bb43-eb39-e012-6433b50dbe7c.png)

### git template write
リストの中の**実在するパスのみ**を`percol`で選択し、`vim`の無名バッファで編集する
`write`は実在するファイルを開き編集するが、保存することは出来ない

![write01.png](https://qiita-image-store.s3.amazonaws.com/0/113398/d33f48c5-bf00-10fa-e6b1-61c134f4510e.png)
![write02.png](https://qiita-image-store.s3.amazonaws.com/0/113398/b56c216e-b03f-f9a2-5240-df14001e7661.png)
![write03.png](https://qiita-image-store.s3.amazonaws.com/0/113398/f56525c2-2958-2479-5c91-14ee05bf6a6c.png)

### git template edit
リストの中の**実在するパスのみ**を`percol`で選択し、`vim`で編集する

保存可能な点以外は`write`と同じ

## やってみたかったこと
+ 丁寧な例外処理
+ git.configを使った設定
+ 公開と配布
+ インストール数を知る
 + GitHubのTraficと言う画面でわかるらしい

## 対応しなかったこと
+ エディタは`vim`固定じゃあなくて`git`で使うエディタを参照してきても良かった
 + とりあえず自分用なので`vim`固定
 + いつか対応するかも
+ `percol`の部分も同様に`peco`と選べても良かった
 + 未対応理由は同上

## 感想
IssueやPRをブラウザで書くときにどうしても`vim`で書きたくて作った
要は`write`が一番やりたかったことで、他のはプラグインとしての体裁を保つためのおまけ

何にせよ晒すと思うとこういう場合の終了コードは普通どうなんだろう？とか色々既存品読んだりして勉強にはなった
