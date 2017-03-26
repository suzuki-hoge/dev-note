失敗の表現方法を考える

自分の考えをまとめる用。

ドメイン層の設計を行う際に、いかに実態に即した失敗表現に出来るかを考えます。

## まず
NullObjectPatternについては[こちらの記事](http://qiita.com/suzuki-hoge/items/b8161d29094224415f1e)で考えをまとめてみました。
このポエムはそれに加えて、DDD的な面を加味してみたり、別の方法を考えてみたりするまとめです。

以前[DDDをHaskellで考える 失敗を表現する](http://qiita.com/suzuki-hoge/items/5b56c7248edaeb81ef2f)という記事を公開しましたが、
これはHaskell力が低いのと、DDD力が低いのと、失敗に対する持論とHaskellでの実現法がごっちゃになってしまっていたところが少し残念だったので、改めてまとめてみました。

まとめ直しはしましたが、この中で触れている「業務ロジック都合で発生する失敗」と「システム都合で発生する失敗」については今でもまったく持論はぶれていません。

## お題
例によってテキトーなお題を用意して、テキトーなコードを書きます。

今回は「名前と年齢から契約を作る。ただし年齢は20以上であること。」という仕様を用意します。
APIが名前と年齢を受け付け、成功した場合は出来た契約を、失敗した場合はエラーメッセージを呼び元に返すイメージです。

契約の永続化も行います。

### コード
```Scala:ContractFactory.scala
object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      Contract(userName, age, Status(1))
    } else {
      ???
    }
  }
}
```

`userName`と`age`を受けて、申込直後(`1`)を意味する`status`と混ぜて契約を作ってくれるクラスがあります。
この例の`???`の部分をどうすべきか、という話です。

### 考えられる失敗の表現
パッと思いつくのは以下4つ

+ 例外
+ NullObjectPattern
+ Optional
+ Either

それぞれのコードを挙げつつ、考えていきます。

### 言語について
言語はとりあえずScalaを採用していますが、動かしていないし、Eitherが使いたいだけなので本質的には何でも良いです。
Javaでやりたければ`javaslang`を使えば良いでしょうきっと。

```Java:UserName.java
class UserName {
  private final String value;

  public UserName(String value) {
    this.value = value;
  }

  public String getValue() {
    return this.value;
  }
}
```

と

```Scala:UserName.scala
case class UserName(value: String)
```

が同じって事ぐらいがわかれば十分です。
シンプルで良いよね。

### パッケージについて
ContractFactoryを`domain`に、Serviceを`service`に置いています。
書きませんが、ServiceはApiから呼ばれます。

## サンプルコード
### 例外
Factoryが、未成年の場合は例外を投げます。

```Scala:domain.ContractFactory
object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      Contract(userName, age, Status(1))
    } else {
      throw new RuntimeException("不正な年齢です")
    }
  }
}
```

```Scala:service.Service
object Service {
  def apply(userName: UserName, age: Age): Contract = {
    val contract: Contract = ContractFactory.create(userName, age)

    ContractRepository.apply(contract)

    contract
  }
}
```

Apiにエラーメッセージを返させるには、例外は捕まえずに上へ伝え、Apiでよしなにエラーメッセージにしてもらいます。

#### 問題点 1
一見いきなり問題が無い様に見えますが、`create`の定義行の型に注目します。

```scala
  def create(userName: UserName, age: Age): Contract = {
```

失敗する可能性を秘めていることがわかりません。
これはクラス図を書いても同じです。

これを僕はドメイン層が仕様を表現しきれていないと考えます。

#### 問題点 2
上記の「ドメイン層が仕様を表現しきれていないと考える」についてですが、僕は**業務仕様上発生するエラーと、システム都合上発生するエラーは別**であると考えています。

前者は今回の「未成年は契約できない」の様な仕様に基づき発生するエラーで、後者は例えば「DBアクセスエラー」とか「通信タイムアウト」等です。

前者はエラーであるけれど**仕様の一部なのでドメイン層に現れるべき**だと考えます。
また逆に、後者は**仕様とは関係なく発生するのでドメイン層に現れないべき**だと考えます。

失敗も含めてひとつの仕様なのだ、という考え方です。

上記の理由により、今回の業務エラーを例外で実装してしまうのは不適切だと考えます。

### NullObjectPattern
FactoryがNullObjectで返します。

NullObjectPatternとは、インターフェースを用意して、成功時と失敗時の具象クラスを別に用意する手法です。

```Scala:Contract
trait Contract {
  def isValid: Boolean
}
```

```Scala:ValidContract
case class ValidContract(userName: UserName, age: Age, status: Status) extends Contract {
  override def isValid: Boolean = true
}
```

```Scala:InvalidContract
case class InvalidContract() extends Contract {
  override def isValid: Boolean = false
}
```

```Scala:domain.ContractFactory
object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      ValidContract(userName, age, Status(1))
    } else {
      InvalidContract()
    }
  }
}
```

```Scala:service.Service
object Service {
  def apply(userName: UserName, age: Age): Contract = {
    val contract: Contract = ContractFactory.create(userName, age)

    if (contract.isValid) {
      ContractRepository.apply(contract.asInstanceOf[ValidContract]) // castが必要
    }

    contract // API層でinvalidだった場合に「契約の作成に失敗しました」とする感じ　Factoryが理由を返せないため
  }
}
```

#### 問題点 1
例外と同じように、`create`の定義行を見ても失敗する可能性に気付くのは難しいです。
（`Contract`がインターフェースであり、具象クラスがNullObjectPatternであると読み解かないといけないため）
ですが、モデル図を書けば解決します。

#### 問題点 2
キャストが必要です。

NullObjectPatternのキャストやそもそも論については、冒頭で紹介した記事を良ければ参照してみてください。

#### 問題点 3
失敗時の`InvalidContract`はドメイン的には何者か。

お題や文脈にも寄りますが、契約し損ねた状態を表すオブジェクトとは何でしょうか。
この例では`InvalidContract`は何も属性を持っていませんし、振る舞いもありません。

（必ずしも常にではありませんが、少なくともこの例では）実装都合で業務上存在しないクラスが必要になってしまっている感じがします。

#### 問題点 4
失敗理由を返せません。

FactoryからApi層まで失敗理由を伝える方法がありません。
`InvalidXxx`に保持させる様な作りにすれば実現できますが、それを型安全に取り出す良い方法が見つかりません。

interfaceである`Contract`に`getErrorMessage()`でも用意したとして、`ValidContract`はどう振る舞うべきでしょうか？
やはりキャストがにおいます。

#### 利点 1
Optionalを採用した場合と比べての利点もあります。

これはOptionalの項で述べます。

### Optional
雰囲気はNullObjectPatternに近いです。

こちらは（Scalaの場合は）`Option`のサブクラスである`Some`か`None`で有無を表現します。

```Scala:domain.ContractFactory
object ContractFactory {
  def create(userName: UserName, age: Age): Option[Contract] = {
    if (age.isValid) {
      Some(Contract(userName, age, Status(1)))
    } else {
      None
    }
  }
}
```

```Scala:service.Service
object Service {
  def apply(userName: UserName, age: Age): Option[Contract] = {
    val contract: Option[Contract] = ContractFactory.create(userName, age)

    contract.foreach(
      ContractRepository.apply
    )

    contract // API層でnoneだった場合に「契約の作成に失敗しました」とする感じ　Factoryが理由を返せないため
  }
}
```

#### 利点 1
`create`の定義行を見るだけで、生成し損ねることがわかります。

また、それをドメイン層的に想定している、つまり業務上発生する失敗であることが表現できています。

#### 利点 2
有の場合だけ永続化する処理がNullObjectPatternより安全に書けます。
（Scalaの`foreach`はJavaの`ifPresent`に相当します）

当然`isPresent()`して`get()`する様な書き方をしているとこの恩恵は薄れますが。

#### 問題点 1
NullObjectPatternと同じく、FactoryからApi層まで失敗理由を伝える方法がありません。

#### 問題点 2
`Some`の場合だけ永続化するのは安全に書けますが、`Some`だと断定して中身を引っこ抜くにはキャストに近い処理が必要になります。

#### 問題点 3
失敗時の挙動はOptionalを受け取った側が責任を持って行う必要があります。
これはNullObjectPatternの利点と裏表になる気がしています。

NullObjectPatternは失敗時にも自前のクラスが返ってくるので、そいつに命令をすることが出来ます。
が、Optionalの失敗時はただ空っぽなだけなので、返された側が何をするべきかを知らなければなりません。

例えば`None`が得られた場合、「エラーログを書くのか？」「アラームを飛ばすのか？」「状況次第では握りつぶすのか？」
呼び元が把握して正しく扱う必要があります。

ですが`InvalidContract`の方はとりあえず「振る舞え」と言えば適切な処理をさせることが出来ます。

### Either
EitherはOptionの「無」の場合を「理由」にすることが出来ます。

`Either[Left, Right]`の様に2つの異なる型を並べて1つの`Either`を現します。
ちなみに、`Right`が成功時の型です。正しい(`Right`)とかかっているのですぐ覚えられます。

```Scala:domain.ContractFactory
object ContractFactory {
  def create(userName: UserName, age: Age): Either[FailureReason, Contract] = {
    if (age.isValid) {
      Right(Contract(userName, age, Status(1)))
    } else {
      Left(FailureReason("不正な年齢です"))
    }
  }
}
```

```Scala:service.Service
object Service {
  def apply(userName: UserName, age: Age): Either[FailureReason, Contract] = {
    val contract: Either[FailureReason, Contract] = ContractFactory.create(userName, age)

    contract.right.map(ContractRepository.apply)

    contract // Api層で左右どちらもjsonにでもしてしまえば良いだけ
  }
}
```

#### 利点 1
`create`の定義行が失敗する可能性があることを表現できています。

`Option`の時より優れているのは、失敗時の型もわかることです。

#### 利点 2
利点 1 に通じますが、仕様上存在する失敗理由というクラス(`FailureReason`)をドメイン層に用意することが出来ます。
実体は`String`のラッパーだろうと`enum`だろうと構いません。

当然Api層まで型安全に理由を伝えられます。

#### 問題点 1
`None`を受け取った場合と同じく、`Left`を返された呼び元側は適切に`Left`を振る舞わせねばなりません。

が、それに付いては以下で述べます。

## 結論
あくまで持論ですが、「仕様上発生する失敗はドメイン層の型で表現し」、「失敗時のドメインクラスも用意できる」Eitherを用いるべきと言うのが結論です。

## おまけ
### 振る舞う失敗とは
`None`および`Left`を受けた側は適切に振る舞わせる必要があり、NullObjectPatternだとそれを自作の失敗クラスに書けるのが利点だと述べました。

で、失敗時の振る舞いについて考えているのですが、すぐ思いつくのは「エラーログ」や「アラーム通知」です。
ですがこいつらはシステム処理の側面が強く、DDD的にはdomain層で行ってしまうのは不適切ではないかと考えています。

```Scala:InvalidContract
case class InvalidContract() extends Contract {
  override def isValid: Boolean = false
  
  def failure() = {
    noticeRepository.failure("契約の作成に失敗しました")
  }
}
```

ドメインは業務ロジックのみに責務を閉じるべきだし、ドメインクラスがリポジトリ（もしくはサービス）の操作をしないと振る舞いが完了しないからです。

ではシステム的な面のない失敗時の振る舞いって何でしょうか。
成功時は契約を生成して、失敗時は理由からエラーメールの文面でも作りましょうか？
それならドメイン層の範疇ですし、ちゃんと実装すればドメイン層からリポジトリのアクセスも発生しません。

```Scala:InvalidContract
case class InvalidContract() extends Contract {
  override def isValid: Boolean = false

  override def getLetterForError():String = {
    "契約の作成に失敗しました"
  }
}
```

こうすればドメインクラスからのリポジトリアクセスはなくなります。
が、`ValidContract`が同じinterfaceを持っているとなると、そっちの`getLetterForError()`はどうすれば良いでしょう。
そこかしこで`if isValid()`だのキャストだのしないといけなそうです。

NullObjectPatternは命ずれば上手く動いてくれるんですけど...
どうもこの辺が「求めるな、命じよ」と上手くかみ合っていない感じがしています。引き続き勉強です。

（追記）
システマチックなことは命じてはいけない、代わりにそれを実現するための素材を命じて吐かせる。が実際の所だと思います。
`notice(reason.getValue ++ "foo...")`ではなくて、`notice(reason.toMessage)`のイメージです。

これをやろうとすると完全に成功と失敗でその後のフローが違ってくるので、やはり同一interfaceではなくて別クラス（しかも両方ドメインクラス！）にするのが良いと一旦落ち着きました。

### ドメインモデルにOptionやEitherが現れるのってどうなの
僕は解無しです、まだ勉強不足な感じ。

Eitherには「失敗するかも知れない」という文脈があるので、ただそれだけでinterfaceを用意して云々とか言うよりよほど言語的に「この処理は失敗するぞ」と示せると思っています。
（ここで言う「言語的」はプログラム言語ではなくて、仕様を表現してその図を見る人と話す際の言語の意味）

が、Eitherの仕様やそもそも存在しない言語とかもあるし、やはり少し実装寄りの発想であることも確かかもしれません。

モデリングしてる段階って、どこまで考えるものなんでしょうかね。
実装イメージは必ず必要だと思うけど、言語選定とかはどうなんだろう。

失敗するってのが分析の結果わかって、さあモデリングって時は、僕は今はEither一択です。
