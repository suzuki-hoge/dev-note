コードに仕様書パスをコメントで書くのやめようよ

（まず追記）
自分たちで新たに作成する仕様書は`Markdown`で記述して`GitHub`で管理しています。
こんなのも書いたくらいだし、そこは犯していないです。[GitHubを中心とした開発プロセス ドキュメント管理](http://qiita.com/suzuki-hoge/items/1d6022cca177e2d96bb5)

この記事内で言う仕様書とは、「エクセルで作られて共有サーバに置いてあるチーム管理外のファイル」を指します。

## こーゆーの、良くあるよね？

```Java
public class FooService {
    /**
     * 仕様書：ad.xxx.net/development/lorem/ipsum/dolor/sit/amet/consectetur/adipiscing/elit/sed/do/eiusmod/tempor
     * incididunt_2.xlsx
     */
    public void apply() {

    }
}
```

見た瞬間「`_2.xlsx`ってなんだよォ...このパス絶対古いんじゃあねェのー？」って思う感じのやつ。

ついでに仕様書のパスが長くって妙なところで改行入ってるおまけ付き。

こんなの見るとイラっとする！

+ コピペしづらい
+ そのパスに仕様書が実在するかわからん
+ 実在するとして、開くのが面倒
+ ある1つの仕様書のパスが1箇所にコメントされていたら、あと数カ所はコメントがあると思う
 + でもちょっと手入れされてたりで数箇所のコメントが同じ場所を指していないことが往々にしてある
+ 仕様書のパスが変わった場合に、ここ以外でもこの仕様書のパスがコメントされている箇所があるかわからん
+ 仕様書の名前(`incididunt_2.xlsx`)を知らないと、全文検索でそのコメントが既にどこかに書かれているか探すことも出来ない
+ コメントされている仕様書一覧が存在しないので見通しが悪い

軽い気持ちで書いたただこれだけのコメントにちょっと考えるだけでもこれだけの悪い点が！

## 文字列のコメントって点が大体の原因では？
なんかいつだったか急に
「コメントで管理とか激ダサだぜ。`Enum`でも作ってそこにリスト作って、アノテーションでちょっと目印入れれば良くね？」
なんて思いついて作ったのが下で紹介する`@DocPath`アノテーション。

超シンプル低コストなのでやってみると良いよ！

例によって`import`文やコンストラクタは適当に略していくので、書くか`lombok`でも使ってね！

### src
まずはこんな感じで`Enum`を作って、パスにラベルを付ける感じでバシバシ定義していくよ！

```Java:doc_path/Path.java
public enum Path {
    API設計方針書("foo.ad.xxx.net/development/api/docs/readme.xlsx"),
    認証について("foo.ad.xxx.net/development/authentication/docs/about.xlsx"),
    DB_会員テーブル("foo.ad.xxx.net/database/tables/users.xlsx"),
    DB_購入物テーブル("foo.ad.xxx.net/database/tables/items.xlsx"),
    サーバ構成資料("foo.ad.xxx.net/infrastructure/docs/service-A003.xlsx"),
    物流システムAPI仕様書("www.xxx.net/development/logistics/api/api.html"),
    在庫管理システムAPI仕様書("www.xxx.net/development/warehouse/api/stocks.html");

    private final String value;
}
```

そんでアノテーションを作る！
ホントに作るだけ。マーカーアノテーションって言うの？（違ったらすいません）

```Java:doc_path/DocPath.java
public @interface DocPath {
    Path path();

    String note() default "";
}
```

これだけじゃ！
使ってみるよー

```Java:service/LogisticsService.java
@DocPath(path = Path.物流システムAPI仕様書)
public class LogisticsService {
    public void apply() {

    }
}
```

備考も書ける！

```Java:service/StockService.java
public class StockService {
    @DocPath(path = Path.在庫管理システムAPI仕様書, note = "引当についてはシート2")
    public void take() {

    }

    @DocPath(path = Path.在庫管理システムAPI仕様書, note = "戻入についてはシート3")
    public void revert() {

    }
}
```

## 利点
まず、ホント`DocPath.java`と`Path.java`を作るだけなので超低コスト！

あとは真面目にいくつか。

+ `Enum`が自分たちが見る仕様書のリストになる
+ 自分たちのチームで通じやすいラベルが付いてる感じになる（パスは`value`で、ラベルが`Enum`の要素名って感じ）
+ ソースから`Enum`へのジャンプはもちろん、エディタの`Find Usase`機能とかを使えばアノテート箇所への逆ジャンプも出来る！
+ パスの修正は当然`Enum`側一箇所で済む

まぁ一言で言うと、コメントから`Java`に昇格したので、エディタの恩恵を受けられる様になるよ！ってことだね。

## 更に
ここまでで十分使えるレベルだし役に立ちます。

ここから先はおまけで他に工夫するポイントを紹介するよ。

この内のいくつかは必要に応じて今のチームでも実現済みだよ。

### アノテーションの体裁を整える
+ `@Target`で`@DocPath`を書ける箇所を明示する
+ `@Retention`で`@DocPath`の有効な範囲を明示する

まぁ大抵は前者はクラス定義とメソッド定義、後者はクラスファイルに含めない、で良いと思う

### Raw String
Windowsで開発していてパスに`\`が含まれる場合は`Raw String`を使うと読み書きしやすいと思う。

その場合は`Path.java`を`Path.groovy`にでもすると良い。

```Java:doc_path/Path.groovy
API設計方針書(/\\foo.ad.xxx.net\development\api\docs\readme.xlsx/),
```

### 見た目を綺麗にしたい
縦を揃えたくなったら、いくつかポイントがある。

```Java:doc_path/Path.java
public enum Path {
    //@formatter:off

    API設計方針書    ("foo.ad.xxx.net/development/api/docs/readme.xlsx"),
    認証について     ("foo.ad.xxx.net/development/authentication/docs/about.xlsx"),
    DB_会員テーブル  ("foo.ad.xxx.net/database/tables/users.xlsx"),
    DB_購入物テーブル("foo.ad.xxx.net/database/tables/items.xlsx"),

    //@formatter:on
```

+ 等幅フォントを設定する
 + IntelliJでRictyを使うには[過去に書いた記事](http://qiita.com/suzuki-hoge/items/98df92eb44eb131de6eb#%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88)があるので参考にしてください
+ 自動フォーマットを無視させる
 + 同じくIntelliJでの設定方法は[こちら](http://qiita.com/suzuki-hoge/items/98df92eb44eb131de6eb#%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%83%E3%83%88%E3%82%92%E9%83%A8%E5%88%86%E7%9A%84%E3%81%AB%E7%84%A1%E8%A6%96%E3%81%99%E3%82%8B)を参考にしてください

（追記）
ずれてる...手元の等幅フォントでは縦揃ってるんだけど、Qiitaのコードシンタックスの中はPフォントなのかな？

### リンク切れを検知したい
ぶっちゃけコメントを辞めて`Java`にした時点で、その辺はもうどうにでも出来る。

`Spock`で適当なテストコードと`check(Path path)`メソッドでも書いて

```Groovy:PathTestSpec.groovy
Path.values().each { check(it) }
```

みたいにしても良いし、`Enum`を振る舞わせる感じで

```Java:doc_path/Path.java
:
:

public void check() {
    // this.valueをどうにかする
}
```

でも良い。

### 開きたい
これもどうとでもなる。

`Enum`に振る舞わせて`Repl`を使うのが一番簡単かなぁ？

```Java:doc_path/Path.java
:
:

public void open() {
    // this.valueをどうにかする
}
```

```Repl
repl> Path.API設計方針書.open()
```

`Groovy`か`Scala`で（まぁ`Java9`ってことはないだろうし）でも動かせるなら、`Repl`から`Enum`自体に開けーって言うのが手っ取り早い。

おまけで、[Macのopenコマンドについて](http://qiita.com/suzuki-hoge/items/21c59c92e07988bb4c3e#open)過去に書いた記事をリンクしておくよ。
要はダブルクリックなので、`.xlsx`ならエクセルが、`.html`ならブラウザが開くので、Macなら`"open " + this.value`で十分！

### 他自由
ダウンロードするなりなんなり好きに出来る。

ただファイルの存在チェックとか外部コマンド（`open`とか`cp`だか`wget`だか）をするなら、`Groovy`とかの方が楽そうだ。

一応掲載したサンプルコードと適当にチラした小ネタで冒頭に書いた不満点はほぼ解消できているはず。

## 他の言語だと？
結局はコメントを定数に突っ込んだってだけなので、何の言語でも似たことは出来ると思う。アノテーションになるのかはわからないけど。

ただ列挙型を作って目に付くところに置けば良いので、ある程度似たことは出来るはず。

嘘コメントパスを撲滅すべし！
