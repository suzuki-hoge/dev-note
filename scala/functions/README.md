部分適用とカリー化、おまけでImplicit Parametersのまとめ

どうも、Scala初心者ですノ

Scalaの勉強をしていて自分なりに部分適用とカリー化の違いが理解できた気がして、
そこからImplicit Parametersも理解できた気がしたのでまとめてみるよ。

## 部分適用とカリー化の例
以下の`f1`と`f2`は普通の関数で、`f3`はカリー化関数（と言う、のかな？）

```Scala
def f1(x: Int) = x

def f2(x: Int, y: Int) = x + y

def f3(x: Int)(y: Int) = x + y
```

呼び方と結果は以下の通り

```Scala
f1(3) // 3

f2(3, 5) // 8

f3(3)(5) // 8
```

`f2`は普通の関数だけど、こんな風に使うと部分適用ってのになる

```Scala
def f2_ = f2(3, _: Int)
f2_(5) // 8
```

### 関数の部分適用って？
**複数の引数の一部だけを先に関数に渡すこと**

### カリー化された関数って？
**1つ引数を渡すと、引数の1つ減った関数を返す関数**

### 上の例で言うと？
例と順番が逆転してしまうけど、カリー化から

`f3`は`x: Int, y: Int`を要求する2引数関数だけど
まず`x: Int`を渡すと、(`y: Int`を要求する1引数関数)を返してくれる様に定義されている

だから`f3(3, 5)`と呼ぶことは出来なくて、`f3`を`(3)`で呼び出し、手に入れた関数をまた`(5)`で呼ばなくてはならない


対して`f2`を`f2_`に部分適用したところは、(1つ引数を渡したので残り1つを要求する関数に変換された)と見えるのでカリー化と同じように見えるけど、
これはカリー化されている関数をそう利用したのではなく、Scalaの言語機能を借りて新しい関数を作ったと考える方が適切だと思った

`_: Int`の力を借りないとこんなイメージ

```Scala
def f2__(n: Int) = f2(3, n)
```

`f2__`に`n: Int`を渡すと、**初めて`f2`の呼び出しが行われる**と言う点がカリー化とは異なる

...で、あってる？

### もっと単純に、結局何が違うかと言うと？
部分適用は普通の関数でも呼び出し側の都合で行える
カリー化は定義側がカリー化関数で定義したら呼び出し側は分けて呼ばないとならない

ってことなんじゃあないかな（Scalaに関しては、だな）

## 部分適用ってどう便利なの？
ここからはチラ裏的なお遊びコードになるよ

### 名前と値段を受け取り、条件次第で永続化したい
普通の本クラスがあるとする

```Scala
case class Book(id: Int, name: String, price: Int)
```

何らかの都合で発番がまだ出来ないとか
永続化すると確定するまで発番をしたくない様な場合に
値を先にまとめてしまうためにコンストラクタに部分適用をしておく、とか

```Scala
val idMissing = Book(_: Int, "foo", 1200)
```

実際に発番を行い、初めて生成される

```Scala
val book = idMissing(allocate()) // Book(1,foo,1200)
```

### 新規契約と同時に購入を受け付け、メールを送信する
普通のメール送信関数があるとする

```Scala
def sendMail(userId: String, subject: String, template: String, items: Seq[String]) = {
  println(
    s"to: $userId, sub: $subject, template: $template items: ${items.mkString(", ")}."
  )
}
```

現時点ではユーザIDと購入物はわからない

```Scala
val sender = Sender.sendMail(_: String, "購入手続き完了のお知らせ", "path/to/template", _: Seq[String])

service(sender)
```

必要な情報は別の何かがかき集めて後から適用してくれる

```Scala
def service(_sender: (String, Seq[String]) => Unit) = {
  // 新規会員登録をする
  val userId:UserId = UserId("abc-123") // 会員登録処理によってIdが払い出される
  
  // 購入手続きをする
  val items = Seq("pen", "book") // 実際は手続き完了によって手に入る情報等を含むItemクラス的なイメージ
  
  // メール送信
  _sender(userId.toString, items) // to: abc-123, sub: 購入手続き完了のお知らせ, template: path/to/template items: pen, book.
}
```

### メリットは？
ちょっと書いてて思ったのは、**値が揃ったらやること**と**値を揃えること**を別々に出来る点なのかな、ってこと
例えばメール送信は汎用部品なので会員登録との依存を無くしたい、けどメール送信には会員の情報が必要、けど会員登録の後に呼びたい！
みたいな場合に、確定している値だけ適用しといて**残りの値は値を集める人に任す**、けど揃えてくれたら**やることはちゃんとやるぜ**
って言う感じに責任分割を出来る

`userId`を適用する部分は別に`toString`じゃあなくて抽象クラスとかでも良い
要は`service()`側が具体的に知りすぎなければ、それだけ`service()`を汎用化させられる

他にも`subject`や`template`と言ったメール固有の値を`service()`まで引き回して依存させるのも防げている

更に例えば、キャンペーン中に申し込んだ人はもっと別の`Sender.sendMailForCampaign()`という違う処理で、もっと元々の引数も多かったのかも知れない
けど、`service()`に渡された部分適用済みの`_sender`はそういうことは知るよしも無く、`String, Seq[String]`を適用して何らかのメールを飛ばすだけだ

## カリー化ってどう便利なの？
カリー化も試し書きしてみたよ

### データベースから何かを取得する
例えばこんなデータベースにアクセスする処理が定義されたクラスがあるとする

```Scala
class Database {
  def select(table: String, id: String): Unit = {
    println(s"select * from $table where id = $id")
  }
}
```

データベースと取得先の値それぞれを受け取る関数がカリー化関数として定義されている

```Scala
def getWith(database: Database)(table: String, id: String): Unit = {
  database.select(table, id)
}
```

カリー化されているので、使う側は`database: Database`と`table: String, id: String`を**別々に適用しなければならない**

```Scala
def service() = {
  val fromDatabase: (String, String) => Unit = getWith(new Database)
  
  fromDatabase("books", "1") // select * from books where id = 1
  fromDatabase("pens", "3")  // select * from pens where id = 3
}
```

これのメリットはまず、ほぼ間違いなく同じ値を適用し続けるであろう`database: Database`の部分だけを先に渡し、ついでに新たな名前を付けて使える様にしている
そのため下2行の呼び出しはとてもすっきり読める

もう一つのメリットは、上の`service()`の例だと`database: Database`は`service()`の引数で受け取ることも出来る点で、
もし以下の様にハードコードしてしまうと、テスト時に他のデータベースに接続したり、モックにしたりすることが出来なくなってしまう

```Scala
def service() = {
  new Database().select("books", "1")
}
```

`Database`や`Session`や`Logger`等、どの呼び出しでも同じ値の場合や
システム都合上渡さねばならないがメインロジックと関係ない様な値、状況次第で切り換えたい様な値を受ける際は
この様に定義しておくと、呼び出し側もシンプルにさせることが出来ると思う

再掲

> 部分適用は普通の関数でも呼び出し側の都合で行える
> カリー化は定義側がカリー化関数で定義したら呼び出し側は分けて呼ばないとならない

### というか、これってただのDIじゃん
依存性注入(Dependency Injection)

DIに関しては調べるといくらでも出るので一言だけで説明すると、
**ハードコードしちゃうと依存度が上がっちゃうのでテストとかしづらいよ、外から注入しようぜ**（超雑）

例を示すために先ほどの`Database`クラスを少し拡張するよ

`Connection`という抽象クラスを用意し、`Database`と`MockJson`クラスを用意した
`Database`クラスは接続先を指定できる様にした
`MockJson`はローカルでデータベースに接続しないで、テキストテストデータで動かすイメージ

```Scala
abstract class Connection {
  def get(table: String, id: String): Unit
}
  
case class Database(url: String) extends Connection {
  override def get(table: String, id: String): Unit = {
    println(s"connect: $url, select * from $table where id = $id")
  }
}
    
class MockJson extends Connection {
  override def get(table: String, id: String): Unit = {
    println(s"open $table.json: key is $id")
  }
}
```

当然`getWith`は抽象クラスである`connection: Connection`を受ける
後の都合で引数の順番は後ろにした

```Scala
def getWith(table: String, id: String)(connection: Connection): Unit = {
  connection.get(table, id)
}
```

こんな感じで接続先を渡してあげると、状況や環境に応じて`service(connection: Connection)`に違う挙動をさせることが出来る
（けど`service`はそれを知らない！`service`は自分がどこに命令しているかは知らず、関心があり責任を負うのはメインロジックだけだ！）

```Scala
def main() = {
  service(new Database("production.db")) // connect: production.db, select * from books where id = 1
  service(new Database("testing.db"))    // connect: testing.db, select * from books where id = 1
  service(new MockJson)                  // open books.json: key is 1
}

def service(connection: Connection) = {
  getWith("books", "1")(connection)
}
```

### おまけのImplicit Parameters
ここまで来たらImplicit Parametersは楽勝だ（最初見た時はなんだこれと思って大いにハマったけど）

引数に`implicit`と書かれた関数を呼ぶ際は、呼び出し箇所から見える範囲内にある`implicit`が付けられた型の合う変数が勝手に渡されるのだ

`connection: Connection`に`implicit`キーワードを付ける

```Scala
def getWith(table: String, id: String)(implicit connection: Connection): Unit = {
  connection.get(table, id)
}
```

例えば`service()`の定義されているクラスのクラス変数として、`implicit`キーワードの付いた変数を定義する
（実際はフレームワークレベルでもっと底の方で定義されるんだろう）

```Scala
implicit val connection = new Database("testing.db")
```

そうすると、`service()`の引数からも実際の呼び出し部分からも`connection`が消えてしまった！ふっしぎー！（に見えてた）

```Scala
def service() = {
  getWith("books", "1") // connect: testing.db, select * from books where id = 1
}
```

Hello Worldを終えた後くらいに`def xxx(...)(implicit ...) = {`なんて見ても意味が全くわからなかったけど、ちょっと丁寧に書いたらすっきり腹落ちした

## おしまい
PythonとかHaskell、それにJavaでSpringをかじっているので、実は`f2_`と`f3`の下りの部分で
DI（Springだと`Autowired`）とオチの`implicit`まで到達はしていたんだけど...
（あ、もしやたまにある`def`の2つ目の`(implicit ...)`って...と）

Javaで書くととても冗長なんだけど、似た様なことは出来なくは無くてたまに書いてた（部分適用とDI）

で、よく「なにこの変なの？」「なんでやってるの？」って聞かれることがあるので
どうやって説明するかな、少し身近?なサンプルって何かな、って考えてたら長くなった

ま、最近ちょっとScala書いてみたので、学習記録というか日記というか、そんな感じのユルい記事としてひとつ
満足
