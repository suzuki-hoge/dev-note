GitHubで閲覧中のリポジトリを切り換えるブックマークレットを作った

作成2分、効果大:D

### おことわり
この記事は複数のリポジトリを頻繁に見る、もしくは切り換える人向けです。

### 需要
会社では同じ組織アカウントの下に大量のリポジトリがあります。
また僕個人のアカウント名の下にもリポジトリが沢山あります。

で、それらを頻繁に切り換える場合、ブックマークだと当然マークしたページに遷移しますね。
大体はそのリポジトリのホームでしょうか。

けど実際は「AリポジトリのIssues」から「BリポジトリのIssues」にジャンプしたい事の方が多いです。
複数のリポジトリのIssuesを全部みたいとか、PullRequestsを全部みたいとか。

### ブックマークレット
こんな感じのブックマークレットを沢山作っておく
当然`dst`は自分で埋める

```JavaScript
javascript:
var dst = 'repo-name';
var src = window.location.href;
window.location.href = src.replace(src.split('/')[4], dst);
```

<img width="1206" alt="image.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/389cea8b-55b4-e6b1-dd73-99b7ae917388.png">

これを押すと`suzuki-hoge/dev-note/pulls`から`suzuki-hoge/repo-name/pulls`に遷移出来る。

### 他
+ 組織アカウントとかも変えたければちょっと改良すれば出来るでしょう
+ `suzuki-hoge/dev-note/pull/2345`から`suzuki-hoge/repo-name/pull/2345`に遷移すると、遷移先にその番号が存在しないとリンク切れになる
  + 遷移前にリンク切れをチェックして、切れてたら`suzuki-hoge/repo-name/pulls`に遷移するとかやっても良い
  + けどとにかく軽く動かしたかったので、リンク切れ覚悟で使う
+ ZenHubを入れるとリポジトリ切り換えプルダウンが出てくるけど、あれはいちいちリポジトリ一覧を参照してるっぽいのでプルダウンを開くのに時間がかかる

### 結論
僕が気に入ったのでベネ
