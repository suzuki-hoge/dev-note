Optionalをうまく使えないエンジニアをEitherとFor式まで一気に連れて行くエクササイズ

どうも、失敗系モナドが大好きな人です。

OptionとEitherのFor式を紹介するために、ステップを踏んだ演習を考えてみました。

折角考えてみたのできれいにまとめて公開してみようかと思います。

# この記事はなに？
## だれ向け？
普段Javaを書いていて、`Optional`をなんとなく使っている後輩達を想定して最初は考えました。

「Java8？よくわからないけど、`null`は`Optional`にすれば良いのね？」
って理解で`null`チェックを`isPresent`に変えただけの人！いませんか？

`Optional`を`if`と`isPresent`での条件分岐に使っている様な人は、是非読んでもらいたいです。

他に、Scalaを触ってみたことがある人、触ってみようと思っている人や、Haskellをちょっと触ったことがあるよ、という人も是非目を通してみたください。

この記事ではScalaの`Option`, `Either`, `For式`について触れますが、例えばHaskellの`Maybe`, `Either`, `do`の様に相当する概念がある言語でも良いと思います。

## お前だれ？
実はScalaの`For式`は初めて読み書きします。
そもそもScalaでの業務経験もありません。

ですが、Haskellを学びながら [HaskellのFunctorとApplicativeFunctorとMonad](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3) や [HaskellのData.Either.Validationを使う](http://qiita.com/suzuki-hoge/items/5178acebb020bc8a519b) という記事を書きました。
根底の概念や考え方はある程度習得できているのではないか、と思います。

とは言えScalaもHaskellも自習のみで経験が浅いので、指摘をしていただけると嬉しいです。

## 何語？
Scalaを用います。

対象読者にJavaの人を含みますが、残念ながらJavaには`For式`がありません。（javaslangにはあるようですが）
調べればすぐにわかる程度の文法しか用いないので、Replを使ったりしながら進められると思います。

（この記事の目的は`Optional`を理解することで、Javaの文法チートシートではありません。
　得たスキルは考え方をJavaで上手く活かすか、言語選定の材料にしてもらいたいと思っています。）

## Repl？
れぷる。

```Scala:Repl
scala> val x = 5
x: Int = 5

scala> x + 2
res0: Int = 7
```

コマンドラインで起動し、その場ですぐ実行できます。
初めて使うクラス等はこれでちょっと触ってみるととても理解がスムーズです。

おそらく普通にインストールをすれば、`scala`コマンドで起動すると思います。

## 単語
以降、`Option`と`Either`で統一します。

`Option`は`Some`と`None`のどちらかで、`Either`は`Right`と`Left`のどちらかとします。
また、`Some`と`Right`を成功、`None`と`Left`を失敗と呼びます。

## やらないこと
Scalaのインストールやエディタの設定等の説明は行いません。

また、最低限Javaの`Optional`に相当する概念を聞いたことはある程度であると、入りやすいかと思います。
（例えばScalaであれば`Option`, Haskellであれば`Maybe`が相当します）

他には例えば`flatMap`の様なメソッドの詳細説明は容量の都合上割愛します。
ヒントを載せるに留めますので、必要であれば調べながら進めてください。

## それでは
一記事に納め、関連コードもQiitaに集約したかったので、かなり長くなってしまっています。
目次はQiitaの生成するインデックスを参照してください。

よろしければ最後までお付き合いいただけると嬉しいです。
是非、都度スクロールする手を止めてコーディングをしてみる事を強くオススメします。

書いて動かす、エディタの出す型のヒントを読み取ろうとする、知らないメソッドを調べる等、大事なスキルの経験値になると思います。

# 演習
## Option基礎
### Optionに慣れる　〜成功チェック、包む、取り出す、写す〜
+ 目標
  + Optionの基本メソッドを知る
  + 文脈という概念を知る
  + 写せるメリットを知る

Optionは、失敗するかも知れないということを表現します。
例えば何らかの値が手に入る**かもしれない**様な場合に、`Some(x)`か`None`を使ってそれを表現します。

Replを使って試してみましょう

```Scala:Repl
scala> val a: Option[Int] = Some(5)  // Someで「成功」を生成
a: Option[Int] = Some(5)

scala> val b: Option[Int] = None     // Noneで「失敗」を生成
b: Option[Int] = None

scala> a.isDefined                   // 成功かチェックしたり出来る
res3: Boolean = true

scala> b.isDefined
res4: Boolean = false

scala> a.get                         // 中の値を取り出せる
res5: Int = 5

scala> b.get                         // けど、失敗に対して中身を要求してはいけない！
java.util.NoSuchElementException: None.get
  at scala.None$.get(Option.scala:347)
  at scala.None$.get(Option.scala:345)
  ... 32 elided
```

Mapからキーで値を手に入れるときなんかがイメージしやすいでしょうか。

```Scala:Repl
scala> val map = Map("result" -> "ok", "code" -> "ok-1")
map: scala.collection.immutable.Map[String,String] = Map(result -> ok, code -> ok-1)

scala> map.get("code")
res0: Option[String] = Some(ok-1)    // 成功したよ（んで、値は ok-1 だよ）

scala> map.get("error-message")      // 失敗したよ（そんなキーは「なかった」よ）
res1: Option[String] = None
```

この様に戻り値がOptionのメソッドは、「失敗するかもしれない、失敗したら何も手に入らない」ということを現します。
**これをOptionの文脈と言ったりします。**

さて、では手を動かしてみましょう。

`Option[Int]`に`Intの2`を加える`def add2(x: Option[Int])`を、上で紹介したメソッドで実装してください。
このメソッドはOptioinの中身がある場合は計算を行い、無ければそれをそのまま返します。箱に数字がつまっているイメージです。

```
+---+             +---+
| 5 | -- add2 --> | 7 |
+---+             +---+

+---+             +---+
|   | -- add2 --> |   |
+---+             +---+
```

上で紹介したメソッドで実装すると、どうなるでしょうか。

**実装タイム**

:
:
:
:
:

```Scala:解答例
def add2(x: Option[Int]) = {
  if (x.isDefined)
    Some(x.get + 2)
  else
    None
}
```

十中八九この様になったかと思います。が、Replの例で`b.get`で例外が発生したことを思い出してください。
そう、`get`は実行例外が発生する可能性があります。

中身を取り出す前に必ずチェックをしなければならないというのは、守りきるのは案外難しいです。
ifのチェックを書き忘れたり、ifの中身だけコピペされたりする恐れもありますし、ifの中で中身と関係ない処理までなんでも書けてしまいます。
正しくチェックをしても、ifの`{`や`return`等をミスするかもしれないし、取り出し方を間違えたり、また詰め直す際にミスをする可能性も考えると、不安の種は尽きません。

原則として、Optionの中身を変えたい場合は、**Optionを自分で剥がすことは推奨されません。**

中身に対して変換処理を行う場合は、`map`というメソッドを使います。
`map`は中身がある場合のみ、中身を使って処理を行い、また詰め直してくれます。

```Scala:解答例
def add2(x: Option[Int]) = {
  x.map(it => it + 2)     // it はつまっていた Int の値を保持する変数で、 it + 2 は x が Some だった場合のみ実行される
}
```

写すという単語は数学の写像から来ています。add2は5を7に写します。

チェックして、Optionを剥がして、計算して、またOptionに詰める、という処理の内、計算部以外はScalaがやってくれています。
Optionの扱い自体はScalaに任せることで、凡ミスをする余地が無くなります。
また「あったら/なかったらと言うOptionの**文脈に関する処理**」と「**メイン**の計算ロジック」を分離することが出来ています。

導入は以上です。
いろいろReplをいじってみてください。

### Option[Int]の足し算　〜全部成功している場合のみ処理する〜
+ 目標
  + いくつかの方法で実現できることを知る
  + flatMapを知る
  + 自分で書くことのリスクを知る

さて、少し演習です。

3つの`Option[Int]`の変数を受け取り、全てが成功していたら加算して`Some[Int]`で、1つでも失敗していたら`None`で返却するメソッドを3種類の方法で実装してください。

```Scala:問1
def sum_by_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  // isDefined と get を用いてください
  // if は入れ子になってはいけません
}
```

```Scala:問2
def sum_by_nested_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  // 同じく isDefined と get を用いてください
  // if を入れ子にしてください
}
```

```Scala:問3
def sum_by_flatMap(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  // isDefined と get を用いず flatMap のみを用いてください

  // flatMap は写した結果がネストした Option になってしまうのを解消します
  // Replで Some(5).map(it => Some(it + 2)) と Some(5).flatMap(it => Some(it + 2)) 等を比べてみてください
  // map で実装すると Some(Some(Some(Some(x)))) になってしまうので flatMap を用います 平らにされる様を強くイメージしてください
}
```

```Scala:実行イメージ
val a: Option[Int] = Some(2)
val b: Option[Int] = Some(3)
val c: Option[Int] = Some(1)

println(
  sum_by_if(a, b, c)         // Some(6)
)

val x: Option[Int] = None

println(
  sum_by_nested_if(a, x, c)  // None
)

println(
  sum_by_flatMap(a, x, c)    // None
)
```

以下に3問まとめて解答例を乗せますが、ひとつずつ確認したい人は上から1メソッドずつ確認してください。

**実装タイム**

:
:
:
:
:

```Scala:解答例
def sum_by_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  if (a.isDefined && b.isDefined && c.isDefined)
    Some(a.get + b.get + c.get)
  else
    None
}

def sum_by_nested_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  if (a.isDefined)
    if (b.isDefined)
      if (c.isDefined)
        Some(a.get + b.get + c.get)
      else
        None
    else
      None
  else
    None
}

def sum_by_flatMap(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  a.flatMap(_a =>
    b.flatMap(_b =>
      c.flatMap(_c => Some(_a + _b + _c))
    )
  )
}
```

大体同じ実装でしたでしょうか？

さて、せっかく書いてみましたが、それぞれのイケてない点をいくつか上げてみます。

`if`を使う方法は、先述の通りチェックや取り出し、入れ直しやフロー制御にバグが入る余地があります。
下のコードのバグっている箇所、一目で分かりますか？（全部のメソッドがバグっています）

```Scala:バグ解答例
def sum_by_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  if (a.isDefined && c.isDefined && c.isDefined)
    Some(a.get + b.get + c.get)
  else
    None
}

// if の別の例
def sum_by_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  if (a.isDefined)
    None
  if (b.isDefined)
    None
  if (c.isDefined)
    None
  Some(a.get + b.get + c.get)
}

def sum_by_nested_if(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  if (a.isDefined)
    if (b.isDefined)
      if (c.isDefined)
        Some(a.get + a.get + c.get)
      else
        None
    else
      None
  else
    None
}
```

（バグは上から1つずつ「`b`のチェックが欠けている」「この場合は`return`が省略できない」「`b.get`をしていない」です）

何をバカなｗ と思うかも知れませんが、実際のコードはもっと複雑ですし、**何よりバグる余地がある時点でイケてない**ですよね。

また`flatMap`の例はリスクは減りましたが、なかなか挙動を一目で理解するのが困難そうです。

### For式登場　〜自分で書かずに安全高品質〜
+ 目標
  + For式を知る
  + 自分で書くより安全でリスクも少ないと知る
  + 実処理と文脈の分離に触れる

さて、今度は同じ問題を`For式`を使って解いてみましょう。

これから使う`for`は、いつものぐるぐる回す時に使う`for`とはちょっと違います。
（とは言え、Optionも最大長1のコレクションと言えるので本質的には同じと捉えられますが、それは今回の範囲外とします）

`Scala for式`等で調べれば使い方は学習できると思いますので、さっそくやってみましょう。

```Scala:問4
def sum_by_for(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] {
  // for のみを用いてください
}
```

**実装タイム**

:
:
:
:
:

```Scala:解答例
def sum_by_for(a: Option[Int], b: Option[Int], c: Option[Int]): Option[Int] = {
  for {
    _a <- a
    _b <- b
    _c <- c
  } yield _a + _b + _c
}
```

こんな感じになりましたか？
やや見慣れない感じがしますが、`flatMap`よりは読み書きが遥かに簡単なはずです。

最初は「`for`の中では`Option`を剥がす事が出来て」、「`yield`でまた`Option`に入れ直してくれる」と考えても良いかもしれません。

エディタを使っているなら、`a`や`_a`の型を見てみてください。
あたかも無思慮にチェックをせず`get`をしている様に見えるかもしれませんが、内部処理的には`flatMap`に置き換えられているので`None`が混入していても当然安全です。

実現方法は`flatMap`に近いですが、見た目は解答例の`sum_by_if`の別解に似ていますね。
上からひとつずつ`Option`を剥がすけど、`None`だったらそこで終了。最後まで`Some`だったら全部足す、と`if`の様に読めます。

これが`For式`です。馴染むまでいじってみましょう。（Replでも複数行書けますし、`;`を使えば1行でも書けます）


リスクと分離という観点から見てみましょう。

`isDefined`, `get`, `map`, `flatMap`, `Some`のいずれも使っていないのが最大のポイントです。

チェック、取り出す、入れ直すという処理はScalaが責任を持ってくれます。
その辺にくだらないバグが入り込む余地が激減しています。

また、実際に記載したコードは総和を求める処理（`yield`の部分）だけですね。
文脈の制御に必要な処理を限りなく見えなくしたので、本当に関心のある処理だけに集中できます。

4つの解答例の中で**一番安全**に**処理だけ**を書けます。
是非とも習得しましょう。

`Option`の基礎はここまでです。

## Either基礎
### Eitherに慣れる　〜成功チェック、包む、取り出す、写す〜
+ 目標
  + Eitherを知る
  + Eitherの基本メソッドを知る

`Option`には慣れましたか？
ここからは`Option`に代わり`Either`の基礎になります。

`Option`は`成功時の値`か`無`で失敗を表現していたのに対し、`Either`は`成功時の値`か`失敗時の値`で失敗を表現します。
一般にはエラー内容を保持したい場合に用いられます。

`Either`では`Some`と`None`ではなく、`Right`と`Left`が提供されます。
`正しい`とかかっているので`Right`が成功の方で、`Left`は大抵はエラーメッセージ等が入ります。

成功時と失敗時の型は異なっても大丈夫です。

`Option[Int]`に対して、`Either[String, Int]`の様に左右両方の型を指定して使います。

Replで触ってみましょう。

```Scala:Repl
scala> val a: Either[String, Int] = Right(5)                    // Rightで「成功」を生成
a: Either[String,Int] = Right(5)

scala> val b: Either[String, Int] = Left("some error message")  // Leftで「失敗」を生成
b: Either[String,Int] = Left(some error message)

scala> a.isRight                                                // チェックしたり
res0: Boolean = true

scala> a.isLeft
res1: Boolean = false

scala> a.right.get                                              // 取り出したり
res2: Int = 5

scala> a.left.get                                               // 実行例外が起きたりするのは大体 Option と同じ
java.util.NoSuchElementException: Either.left.value on Right
  at scala.util.Either$LeftProjection.get(Either.scala:289)
  ... 32 elided
```

Scalaの`Either`を返すメソッドの例がすぐにわからなかったのですが、例えば認証とかだとイメージできるでしょうか？

```Scala:Repl
def authentication(userId: UserId, password: Password): Either[String, User] {
  // 中身は割愛
}

println(
  authentication(foo, password) // Right(User(略))
)

println(
  authentication(bar, password) // Left(IdかPasswordが不正です)
)

println(
  authentication(baz, password) // Left(Id状態が不正です)
)

// 認証だと外部通信とか発生しちゃうので、関数的という点では例として不適切だったかも...
```

`authentication`の型を見てください。

`UserId`と`Password`で認証をして、成功したら`User`を、失敗したら`String`を返す、と読めます。
この失敗しても何かを返すよ、というのが**Eitherの文脈**と言えますね。

引数の型と戻り値の型と文脈があると、メソッド定義から得られる情報はとても表現が言語的になると思いませんか？


ところで`Either`にも`Option`と同じ様に`map`もありますが、`right`か`left`どちらにかけるかを指定して使います。

`map`の練習として、今度は`Either[String, Int]`に`Intの2`を加える`def add2(x: Either[String, Int])`と、
`String`を大文字にする`def toUpper(x: Either[String, Int])`を実装してみましょう。

```
+---------------+                     +---------------+
|           | 5 | -- right add2   --> |           | 7 |
+---------------+                     +---------------+

+---------------+                     +---------------+
| foo-error |   | -- right add2   --> | foo-error |   |
+---------------+                     +---------------+

+---------------+                     +---------------+
|           | 5 | -- left toUpper --> |           | 5 |
+---------------+                     +---------------+

+---------------+                     +---------------+
| foo-error |   | -- left toUpper --> | FOO-ERROR |   |
+---------------+                     +---------------+
```

解答例は割愛しますが、ひとつ大きなポイントがあります。
それは**Intの2を加える処理を文脈ごとに書いている点**です。

`def add2(x: Option[Int])`と`def add2(x: Either[String, Int])`を別に作るはめになってしまっていますね。
しかも例えば、左の型が変わった`Either[Int, Int]`の右側に`Intの2`を加えたい場合は、また`add2`を作るのでしょうか？

いくらなんでもそれはナンセンスですね。
これは`add2`が**文脈に関する処理**と**メインの計算ロジック**両方を持ってしまっている事に起因します。

直してみましょう。

`add2`から文脈に関する処理を消し、本来やりたかった`Int + Int`の処理のみとして定義します。

```Scala
def add2(x: Int): Int = {
  x + 2
}
```

そして、文脈に関する処理は`Scala`に任せて、メインロジックの部分は文脈と関係なく組み合わせます。

```Scala
println(
  Some(5).map(add2)        // Some(7)
)

println(
  Right(5).right.map(add2) // Right(7)
)
```

こうすれば今後文脈が変わる場合にも`add2`を改修する必要がありません。
`add2`は文脈は知らず、ただ`Int + Int`の動作保証にだけ注意していれば良いのです。

これが**文脈とロジックの分離**です。

### Either[String,Int]の足し算　〜全部成功している場合のみ処理する〜
+ 目標
  + Optionとは違うメソッドで実現しなければいけないことを知る
  + 違う文脈を自分で書くとまた別の落とし穴があることを知る

さて、では演習です。

`Option[Int]`の足し算を、今度は`Either`でやってみましょう。

3つの`Either[String, Int]`の変数を受け取り、全てが成功していたら加算して`Right[String, Int]`で、1つでも失敗していたら`Left[String, Int]`で返却するメソッドを3種類の方法で実装してください。
**失敗していた場合は、最初に検出した失敗を返却してください。**

```Scala:問1
def sum_by_if(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  // isRight と get を用いてください
  // if は入れ子になってはいけません
}
```

```Scala:問2
def sum_by_nested_if(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  // 同じく isRight と get を用いてください
  // if を入れ子にしてください
}
```

```Scala:問3
def sum_by_flatMap(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  // isRight と get は用いず flatMap のみを用いてください 

  // Replで Right(5).right.map(it => Right(it + 2)) と Right(5).right.flatMap(it => Right(it + 2)) 等を比べてみてください
}
```

```Scala:実行イメージ
val a: Either[String, Int] = Right(2)
val b: Either[String, Int] = Right(3)
val c: Either[String, Int] = Right(1)

println(
  sum_by_if(a, b, c)        // Right(6)
)

val x: Either[String, Int] = Left("error x")
val y: Either[String, Int] = Left("error y")

println(
  sum_by_nested_if(x, b, c) // Left("error x")
)

println(
  sum_by_flatMap(a, x, y)   // Left("error x")
)

println(
  sum_by_if(a, y, x)        // Left("error y")
)
```

以下に3問まとめて解答例を乗せますが、ひとつずつ確認したい人は上から1メソッドずつ確認してください。

**実装タイム**

:
:
:
:
:

```Scala:解答例
def sum_by_if(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  if (a.isLeft)
    return Left(a.left.get)
  if (b.isLeft)
    return Left(b.left.get)
  if (c.isLeft)
    return Left(c.left.get)
  Right(a.right.get + b.right.get + c.right.get)
}

def sum_by_nested_if(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  if (a.isRight)
    if (b.isRight)
      if (c.isRight)
        Right(a.right.get + b.right.get + c.right.get)
      else
        Left(c.left.get)
    else
      Left(b.left.get)
  else
    Left(a.left.get)
}

def sum_by_flatMap(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  a.right.flatMap(_a =>
    b.right.flatMap(_b =>
      c.right.flatMap(_c => Right(_a + _b + _c))
    )
  )
}
```

どうですか？この様な感じになったでしょうか？

大体の雰囲気は`Option`の時と同じですね。

`Option`の時と違うのは、大きくは1点です。
それは、**失敗時は最初の失敗の中身を返さないといけない**ことです。

`Option`の時はとにかく`None`で良かったのですが、`Either`の場合は`Left`でも自分で制御して最初の`Left`を把握しなければなりません。
ですので`Option`の例にあった`if (a.isDefined && b.isDefined && c.isDefined)`の様な書き方は出来なくなりましたね。

文脈が変わった事により**コードが少し変わり**、**気をつけなければいけない事が変わりました**ね。

### For式登場　〜自分で書かずに安全高品質〜
+ 目標
  + Optionとほぼ同じ記述で実現できることを知る

同じ様に`Either`も`For式`を使って解いてみましょう。

大きくは`Option`と変わらないので、さっそく問題です。

```Scala:問4
def sum_by_for(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] {
  // for のみを用いてください
}
```

**実装タイム**

:
:
:
:
:

```Scala:解答例
def sum_by_for(a: Either[String, Int], b: Either[String, Int], c: Either[String, Int]): Either[String, Int] = {
  for {
    _a <- a.right
    _b <- b.right
    _c <- c.right
  } yield _a + _b + _c
}
```

`Option`とほぼ同じ書き方で出来ました。

これも`Option`の時に述べたのと同様、自分でチェックや取り出し入れ直しを書いていないですね。
それに動作イメージは`flatMap`なので、当然ちゃんと最初に失敗した`Left`が返されます。シンプルで強力ですね。

唯一`Option`と違う点は左右の指定ですが、それについての詳細は割愛します。
気になる方は最下部の参考リンクをご覧ください。

`Either`も、なんとなく使える気がしてきましたか？

## 応用
+ 目標
  + 実践に活かせそうな状況を知る
  + 既存のクラスに文脈を付与しても既存コードに改修が不要なことを実感する
  + 文脈を付与しても既存クラスのテストが増えない事を実感する
  + 文脈と既存クラスに異存が無いことを知る

ここからは少し実用例っぽい？お題をやってみて、馴染み始めた`Option`と`Either`をもっと馴染ませていきます。

解答例は一意ではありませんが、一応解答例も載せるのでぜひまずは自分で書いてみてください。

### お題（共通部）
ユーザの入力を受け付けて`Mail`クラスのインスタンスを生成するのが大きな目標です。

それを`Option`で実装し、仕様追加をして`Either`で再実装します。
この「お題（共通部）」の項ではどちらにも共通する仕様について記載します。

まず既存クラスとして、以下のクラスが提供されます。
個人情報を渡すとメールの情報を組み立ててくれる`Mail.registration`がコアロジックです。

```Scala:コアクラス
case class FirstName(value: String)

case class LastName(value: String)

case class MailAddress(value: String)

case class Mail(to: String, sub: String, body: String)

object Mail {
  def registration(mailAddress: MailAddress, firstName: FirstName, lastName: LastName): Mail = {
    Mail(mailAddress.value, "新規登録受付のお知らせ", "ようこそ、%s %sさん。".format(firstName.value, lastName.value))
  }
}
```

姓、名、メアドを文字列で受け取り、メールを組み立ててください。
ただし以下で示すバリデータを通し、全てが成功だった場合に成功の`Mail`を、そうでない場合は失敗を返してください。

全て成功だった場合にのみ`Mail`を組み立てる処理を、基礎編でやった様に`if`, `nested_if`, `flatMap`, そして`For式`それぞれで実装してください。

お題の共通部は以上です。

### 実践風Option　〜バリデーションして組み立てる〜
ユーザの入力をバリデートする処理ですが、成功しているか失敗しているかだけがわかれば良いです。
失敗理由は不要ですので`Option`が適切です。

以下の様なバリデータを用意してください。

```Scala:バリデータ
def validateFirstName(value: String): Option[FirstName] = {
  // 空文字は失敗
  // それ以外は成功
}

def validateLastName(value: String): Option[LastName] = {
  // 空文字は失敗
  // それ以外は成功
}

def validateMailAddress(value: String): Option[MailAddress] = {
  // 空文字は失敗
  // @ が2つ以上ある場合も失敗
  // それ以外は成功
}
```

これが全て通った場合に成功の`Mail`を返すとは、つまり`Some(Mail)`を返す、もしくは`None`を返すという意味です。

実行例を記載します。

```Scala:実行例
val firstName = validateFirstName("John")
val lastName = validateLastName("Doe")
val mailAddress = validateMailAddress("big-boss@fox.com")

println(
  createRegistrationMail_if(firstName, lastName, mailAddress)
) // Some(Mail(big-boss@fox.com,新規登録受付のお知らせ,ようこそ、John Doeさん。))

val invalidFirstName = validateFirstName("")

println(
  createRegistrationMail_flatMap(invalidFirstName, lastName, mailAddress)
) // None
```

以下の7メソッドを実装して動作確認をしてください。

+ `validateFirstName`
+ `validateLastName`
+ `validateMailAddress`
+ `createRegistrationMail_if`
+ `createRegistrationMail_nested_if`
+ `createRegistrationMail_flatMap`
+ `createRegistrationMail_for`

**実装タイム**

:
:
:
:
:

出来ましたか？
バリデータの中身は普通に`if`か`match-case`でしょうから、解答例は割愛します。
組み立てのコードは代表して`if`と`for`の例を掲載します。

```Scala:解答例
def createRegistrationMail_if(firstName: Option[FirstName], lastName: Option[LastName], mailAddress: Option[MailAddress]): Option[Mail] = {
  if (firstName.isEmpty)
    None
  else if (lastName.isEmpty)
    None
  else if (mailAddress.isEmpty)
    None
  else
    Some(Mail.registration(mailAddress.get, firstName.get, lastName.get))
}

def createRegistrationMail_for(firstName: Option[FirstName], lastName: Option[LastName], mailAddress: Option[MailAddress]): Option[Mail] = {
  for {
    f <- firstName
    l <- lastName
    m <- mailAddress
  } yield Mail.registration(m, f, l)
}
```

（解答例の解説は`Either`が終わってからまとめてやります）

### 実践風OptionをEitherで拡張　〜組み立てられなければエラーメッセージを返す〜
では仕様変更です。

バリデートの結果を呼び出し元に教えなくてはなりません。

バリデータを以下の様に改修し、メール組み立て部も成功の`Mail`か最初に発生したバリデーションエラーのメッセージに改修してください。

```Scala:バリデータ
def validateFirstName(value: String): Either[String, FirstName] = {
  // 空文字は失敗
  // それ以外は成功
}

def validateLastName(value: String): Either[String, LastName] = {
  // 空文字は失敗
  // それ以外は成功
}

def validateMailAddress(value: String): Either[String, MailAddress] = {
  // 空文字は失敗
  // @ が2つ以上ある場合も失敗
  // それ以外は成功
}
```

実行例です。

```Scala:実行例
val firstName = validateFirstName("John")
val lastName = validateLastName("Doe")
val mailAddress = validateMailAddress("big-boss@fox.com")

println(
  createRegistrationMail_if(firstName, lastName, mailAddress)
) // Right(Mail(big-boss@fox.com,新規登録受付のお知らせ,ようこそ、John Doeさん。))

val invalidMailAddress1 = validateMailAddress("")
val invalidMailAddress2 = validateMailAddress("big@boss@fox.com")

println(
  createRegistrationMail_nested_if(firstName, lastName, invalidMailAddress1)
) // Left(MailAddressが空です)

println(
  createRegistrationMail_flatMap(firstName, lastName, invalidMailAddress2)
) // Left(@が2つ以上あります)
```

`if`, `nested_if`, `flatMap`, `for`それぞれで実装してください。
これで実装は最後です。

**実装タイム**

:
:
:
:
:

何度も繰り返し演習してきたので、もうあまり悩みませんでしたかね？
`Option`の時と同様に、`if`と`for`の例のみを掲載します。

```Scala:解答例
def createRegistrationMail_if(firstName: Either[String, FirstName], lastName: Either[String, LastName], mailAddress: Either[String, MailAddress]): Either[String, Mail] = {
  if (firstName.isLeft)
    Left(firstName.left.get)
  else if (lastName.isLeft)
    Left(lastName.left.get)
  else if (mailAddress.isLeft)
    Left(mailAddress.left.get)
  else
    Right(Mail.registration(mailAddress.right.get, firstName.right.get, lastName.right.get))
}

def createRegistrationMail_for(firstName: Either[String, FirstName], lastName: Either[String, LastName], mailAddress: Either[String, MailAddress]): Either[String, Mail] = {
  for {
    f <- firstName.right
    l <- lastName.right
    m <- mailAddress.right
  } yield Mail.registration(m, f, l)
}
```

以上で実装は全てお終いです、お疲れ様でした。

### お題をやってみてのまとめ
`For式`の書き方は知れましたね？

ここではお題で扱った`Mail.registration`に注目してこの設計のメリットを考えてみます。

#### ロジックと文脈
まず`Mail.registration`のやってくれていることとして、以下の様なコアロジックが存在するところから始めました。

+ 宛先は`MailAddress`の値をToにすること
+ 新規登録時は「新規登録受付のお知らせ」という件名であること
+ 本文は「ようこそ」ではじめて、姓と名は半角で繋ぐこと

これが**ロジック**です。

対して「全て成功していれば成功に包んで生成する、失敗していれば適切な失敗を返す」という要求が**文脈の処理**です。

解答例の`if`の方も`for`の方も、この**ロジックと文脈処理の分離**をちゃんとやっています。
ここが出来ているので、`Mail.registration`の改修を一切しなくて済みました。

文脈が増えてもコアロジックの改修が不要ですし、逆にコアロジックの変更があった場合に文脈の数だけ直したりもしなくて済みます。

加えてもう一つが、**自分で文脈に関する処理を極力しない**ために、`if`より`for`の解答例の方が高可読性で低記述量だからおすすめだ、ということでした。

以上の理由から、`For式`の利用を（僕は）強く推奨します。

#### 剥がすという捉え方に関する補足
> 最初は「`for`の中では`Option`を剥がす事が出来て」、「`yield`でまた`Option`に入れ直してくれる」と考えても良いかもしれません。

初めに上記の様に「`Option`を剥がせる」と書きましたが、こう捉えるのであれば`Option`は`文脈`に読み替える方がより適切だと思います。

`for`の中では**文脈を剥がせて**、`yield`でまた**文脈に入れ直す**のです。
従って`for`を使う限りでは**文脈がなくなってしまったり出し入れを間違えたりする事がなく、適切な文脈が保たれることが保証される**と考えています。

#### 実際に使う
この辺りまで理解していて、かつ言語がそれを出来るのか否かで`Option`や`Either`の使い方を考えられたら良いと思います。

「俺らの`Optional`ではこれは真似出来ねー」と思う場合は、それが`Optional`の使い方として適切なのか、それとも言語上出来ないのかを考えてみると良いと思います。

使い方が不適切な場合は、`Optional`をフラグの様に扱っていたりする場合か、`Optional`で包む切り口がおかしい場合が多いと（周りを見る限りではとても）思います。

例えば`optional.isPresent()`を連打して処理を分岐する様なことはただのフラグ管理です。
ひどい場合は`isPresent`の場合に別にそれの`get`をしないで別の値を操作する様なことがあります。
これは明らかなフラグによる分岐ですし、そもそも`Optional`に包む物の切り口もおかしいです。

文脈からは出さずに、写す。という発想をしてみると変わるかもしれません。

言語上の問題であれば、`Java`であれば`javaslang`を使えば似た事が出来る気がします。（詳細は割愛）

#### 使いどころ
これはもう業務やチームや言語によるので、正直なところ「ここまでを習得した上で、それを織り込んで設計と言語選定をするしか無い」と思います。

それでも現存するコードの中でなんとか局所的に使えそうな所としては、以下の様な箇所がすぐに思いつきました。

+ Databaseのカラムをクラスに変換するORM層
  + 例えば`解約予定日`、`解約予約日`, `解約理由`の全てが`非null`なら云々、みたいな処理
+ 複数のチェックロジックを連打する層
  + 例えば`会員状態のチェック`、`商品の組み合わせチェック`、`在庫のチェック`が全て成功なら云々、失敗なら理由を、みたいな処理

# おしまい
どうでしたか？
それぞれの項目に目標を掲げていたので、意図したことを実感してもらえたなら良いのですが。

Java8になって`Optional`に初めて触れた人が多い様に感じますが、単純なNPE脱却の次のステップや、他言語にある本来の意図の様な物を紹介出来たでしょうか？

僕自身はこれらは全部Haskellで学びました。
他言語を学ぶ事で別の言語の理解が深まる事は多いと思いますが、全然違う言語を0から学ぶのは敷居が高いのもありますし、この記事が誰かの学習素材として役立てばうれしいなと思います。


それにしても、なが〜〜い記事だ！
もしここまで読んでくれている人がいたら、ありがとうございます！

# 参考
参考資料としていくつかを掲載します。

興味があれば見てみてください。

+ 「最初のエラー」ではなくて「全てのエラー」を返したい場合、`Validation`というのがあります
  + [EitherとValidation](http://slides.pab-tech.net/either-and-validation/#1)
  + `scalaz`ですが、`validation`の例があります
  + 他にも`applicative`や右優先について書いてあります
+ 執筆終盤でほぼ同じ事を言っている記事があることに気付きましたｗ
  + [Option型を使いこなして初心者から中級者へ](http://sssslide.com/speakerdeck.com/daiksy/scala-fukuoka)
  + `Either`は少なめ
  + コレクションに焦点を当てて？書かれています
+ `For式`の仕組み自体に興味が出たら
  + [HaskellのFunctorとApplicativeFunctorとMonad](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3)
  + 僕の記事で恐縮ですが、「すごいHaskell楽しく学ぼう」の学習記録です
  + 文脈の扱いをとても体系立てて学べます
  + 本当にオススメするのは本自体ですがいきなり本は買わないと思うので、雰囲気だけでも見てみたければ
