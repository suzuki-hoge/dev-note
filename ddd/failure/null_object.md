失敗を表現する手法としてNullObjectパターンが不適切でEitherが適切だと思う理由

真面目な気分出して書いていたらすごい長くて堅苦しくてもったいぶった感じになってしまった...
この記事の9割は壮大な前置きですw

## なにこれ
失敗の表現としてNullObjectパターン（以下楽なので勝手にNOPとします）を使うべきか議論をした際に論理立てて話せなかったので、
持論整理をしてついでにこの場を借りて晒してみようと言う記事です。

全ての状況において必ずEitherだ！と言うよりは、議論になったら僕はこう考えてますって言うためのポエムです。

## 先に結論
前置きではない1割の部分だけ先出します。
それで「あ、そうか」とか「は？」とか思える人は以下の長大な前置きは不要ですw

NOPは成功と失敗を区別しようとすると破綻する、けど区別したい事が珍しくない。
成功と失敗を区別したくなった場合に同じインターフェースを実装している事が破綻の要因だと思うので、NOPではなくてEitherを使う。

です！

## NOPとは
ここから前置きが始まります。

ちゃんとした?手法なので、調べればいくらでも資料は出ますが、この記事を読むための要点だけ記載します。

### NOPを用いないコード
`Foo`を返す`findFoo()`という参照ロジックがあります。
この`findFoo()`は何も見つからなかった場合に`null`を返します。

みつかった`foo`に何か命令をしたい場合に、**呼び出し側が忘れずにnullチェックを行う必要があります。**

```Java:Main.java
Foo foo = findFoo();

if (foo != null) {
    foo.fileWrite("path/to/dir");
}
```

```Java:Foo.java
public class Foo {
    public void fileWrite(String path) {
        System.out.println("write to " + path);
    }
}
```

このコードの問題は大きく二つあります。

+ 呼び出し側がチェックをしなければならない、当然呼び出しが複数箇所にあれば全てで漏らさずチェックが必要
+ `findFoo()`の実装を読まないとnullチェックが必要か判断できない

これを改善する手法として、NOPが用いられます。

### NOPを用いるコード
端的に言うと、`Foo`をインターフェースにし、失敗時の挙動も`Foo`側が責任を持って用意しておく様なイメージです。

```Java:Foo.java
public interface Foo {
    public void fileWrite(String path);
}
```

```Java:ExistingFoo.java
public class ExistingFoo implements Foo {
    @Override
    public void fileWrite(String path) {
        System.out.println("write to " + path);
    }
}
```

```Java:NonexistentFoo.java
public class NonexistentFoo implements Foo {
    @Override
    public void fileWrite(String path) {
    }
}
```

```Java:Main.java
Foo foo = findFoo();

foo.fileWrite("path/to/dir");
```

`Foo`は必ず命令を受けられるとインターフェースで定めておき、参照結果が無かった場合(null時に相当する場合）は命令は受けるけど空振りをする、という設計です。

これにより先述の問題点を改善しています。

> + 呼び出し側がチェックをしなければならない、当然呼び出しが複数箇所にあれば全てで漏らさずチェックが必要
> + `findFoo()`の実装を読まないとnullチェックが必要か判断できない

+ 呼び出し側はチェックが不要
+ `findFoo()`がNOPを採用していれば安心して命令して良い

これは安全ですね。

## 値変換を行う
振る舞いを増やしてみます。
`Foo`は`ExistingFoo`の場合は`Status`を持ってるとし、`statusUpdate()`を命じる事で新たな`Foo`を作らせます。
（`statusUpdate()`は「求めるな、命じよ」や「イミュータブルオブジェクト」の考え方を含みますが、本記事では触れません。）

簡単なコードなので、増えた分だけを書きます。

```Java:Status.java
public enum Status {
    BEFORE_FILE_WRITE, AFTER_FILE_WRITE
}
```

```Java:Foo.java
public Foo statusUpdate();
```

```Java:ExistingFoo.java
private final Status status;

@Override
public Foo statusUpdate() {
    return new ExistingFoo(Status.AFTER_FILE_WRITE);
}
```

```Java:NonexistentFoo.java
@Override
public Foo statusUpdate() {
    return new NonexistentFoo();
}
```

```Java:Main.java
Foo foo2 = foo.statusUpdate();
```

`NonexistentFoo`の場合は`Status`は持っていませんし、`statusUpdate()`を命じられても引き続き`NonexistentFoo`であり続けます。

依然として呼び出し側は何のチェックも無く、何も考えずに安全に命じる事が出来ています。

ここまでは素晴らしいと思います。


以下、`ExistingFoo`が得られた場合を「成功時」、`NonexistentFoo`が得られた場合を「失敗時」と言います。

## 成功時だけDBに保存したい
さて、成功時だけこの`Foo`を別メソッドに渡したいと思います。

ですが、別メソッドは`Foo`および`NonexistentFoo`には対応していません、`ExistingFoo`しか受け取れません。
参照結果の永続化がイメージし易いと思うので、保存メソッドを作ります。

実装方針は、失敗成功を`Foo`に尋ねてからキャストするとします。

```Java:Foo.java
public boolean isExisting();
```

```Java:ExistingFoo.java
@Override
public boolean isExisting() {
    return true;
}
```

```Java:NonexistentFoo.java
@Override
public boolean isExisting() {
    return false;
}
```

```Java:Main.java
if (foo2.isExisting()) {
    save((ExistingFoo) foo2);
}
```

今回用意した`isExisting()`の本質は何でしょうか？
これは`instanceof`とやっていることが変わりません。
そしてキャストを行います。

NOPを用い始めた頃を思い出してください。
nullチェックをしなくて良い設計だったはずなのに、型チェックをしてキャストを行っています。

型チェックはnullチェックと本質的には変わりません。
成功を`Foo`、失敗を`null`で表しnullチェックしていたことが
成功を`ExistingFoo`、失敗を`NonexistentFoo`で表し`ExistingFoo`チェックしているだけだからです。

依然としてチェックをし忘れてはならないという問題が付きまといますし、漏らした場合はキャスト例外が発生します。
これではクラス・コードを増やしたのに、発生する例外がぬるぽからキャスト例外に変わっただけです。

## 失敗時だけエラーメッセージをログに出力したい
しつこいですが、今度は失敗時だけエラーログを書きたいと思います。

どうやって実装しましょう？

```Java:Main.java
if (!foo2.isExisting()) {
    writeLog(foo2.getErrorMessage());
}
```

どうもうまいやり方が見つかりません。
失敗時の判断は先に作った`isExisting()`で可能ですが、`ExistingFoo`は`getErrorMessage()`で何を返すべきでしょうか？
空文字？まさかnull？それともエラーメッセージもNOPにする？

実際にそれらの例を実装する価値はないと思うので、サンプルコードはここまでとします。

（補足）
求めるな命じよの観点からすると、`foo2.writeErrorLog()`を用意して、`ExistingFoo`は空振りをするのが妥当そうです。
が、今回はエラーメッセージを「手に入れたかった」のでこの様な例にしています。
とは言え、戻り値でエラーメッセージを返さなければいけない様な状況も多分にあると思うので、不適切な例だとは思いません。

## どこでおかしくなったのか
ここからが本題です。

> ここまでは素晴らしいと思います。

と、`fileWrite()`と`statusUpdate()`の例の後で述べました。

その後に`save(ExistingFoo foo)`と`writeLog(String str)`をやり出したらおかしくなり始めました。

今回書いてみた4例の内、先の2例と後の2例では決定的に異なることがあります。

それは**成功・失敗を意識するかしないか**です。

### NOPはストラテジパターンではないか
GoFのデザインパターンの中に、ストラテジパターンというのがあります。

今回の`Foo`の例前半の様に、実行時に具体クラスが何かを気にせず命令する設計です。
（コード例はかさばるので今度は図で済ませてみます）
![Figure.png](https://qiita-image-store.s3.amazonaws.com/0/113398/e195c2f0-ce4a-9d29-d15f-5c95d3ce50b7.png)

クラス図および実装的には、`Figure`と`Foo`は変わりません。
なのでNOPはストラテジパターンの具体クラスの部分が2つ固定で、それぞれが成功と失敗であると言う特殊ケースなのだと考えられます。

なので`fileWrite()`と`statusUpdate()`の様な**具体クラスが何であれ、命じれば良い**処理は得意です、それはもう素敵に書けます。
ですが**成功（失敗）だけを意識するのは極めて苦手**です。interfaceを使って抽象度を上げる設計ですから当然です。

### 成功と失敗が同じinterfaceを実装すること自体が不適切
持論を述べる記事なので、そう言い切ります。

今回の`Foo`の最終的な状態は、以下の様になりました。

+ `ExistingFoo`
  + ステータスを持っている
  + DBに保存する必要がある
+ `NonexistentFoo`
  + エラーメッセージを持っている

これはもはや別物でしょう？
全く同列関係では無い2つのクラスをinterfaceで同一視してしまっているので、型チェック(`isExisting()`)とキャストがなくせないのです。

## Eitherの導入
ではどうするべきかですが、Interfaceを用いないで「2つのクラスどちらか」を実現する方法のひとつにEitherという手法があります。

（残念ながらJava8には標準でありませんので、[Javaslang](http://www.javadoc.io/doc/io.javaslang/javaslang/2.1.0-alpha)を用いるか、標準で用意されている[Scala](http://www.scala-lang.org/api/rc2/scala/Either.html)等を用いる必要があります。
　以後は何らかの方法でJavaに`Either<L, R>`を用意したと想定します。）

Eitherは失敗を扱うための概念であり、2つの型を指定して使います。そして実行時には必ずどちらかの型の値が保持されます。
個数を計算するが失敗時はエラーメッセージを返す、という例は以下の様になります。

```Java
Either<String, Int> result = count(a, b, c, ...);
```

これは計算に成功すると`result`はIntを保持し、失敗すると`result`はStringを保持します。
（左が失敗時、右が成功時の型です。正しいのRightとかかっています。）

IntとStringは当然同じinterfaceを持ちませんが、「どちらか」を実現できています。

### NOPとEitherの違い
NOPはinterfaceを用いて**成功と失敗の同一視**を行います。
対してEitherはinterfaceを用いず**成功と失敗は別視**します。

成功と失敗という対になる概念を扱うには、明らかにEitherの方が適していると考えます。

### FooをEitherで書いてみる
Javaでサンプルコードを書く都合上、架空のEitherを用います。

`ExistingFoo`と`NonexistentFoo`の名前はそのまま使いましょう。
ですが、`Foo`というinterfaceは破棄します。

```Java:ExistingFoo.java
public class ExistingFoo {
    private final Status status;

    public void fileWrite(String path) {
        System.out.println("write to " + path);
    }

    public ExistingFoo statusUpdate() {
        return new ExistingFoo(Status.AFTER_FILE_WRITE);
    }
}
```

```Java:NonexistentFoo.java
public class NonexistentFoo {
    public String getErrorMessage() {
        return "Fooが存在しません";
    }
}
```

それぞれが本当に必要なことだけを残したら、やっぱりどう見ても全然違うクラスです。

扱ってみます。
（Eitherは今超適当に作りました。）

```Java:Main.java
Either<NonexistentFoo, ExistingFoo> either = findFoo();

either.consumeR(
        r -> save(r.statusUpdate())
).consumeL(
        l -> writeLog(l.getErrorMessage())
);
```

`consumeR()`は、実体がRightの時だけ動き、Left時は空振りに終わります。`consumeL()`も逆に同様です。
`either`には成功時の命令と失敗時の命令を与え、どちらか片方が実行されます。

`.consumeR(r -> ...`の`r`は確実に`ExistingFoo`です。型チェック等は必要ありません。
そもそも`NonexistentFoo`と`ExistingFoo`を同一に扱ってしまえるinterfaceが無いので、型チェックやキャストが出る余地はありません。

あと今気付きましたが、チェインするよりこんな感じの方が良さそうですね。Scalaっぽいな。

```Java:Main.java
either.consume(
        r -> save(r.statusUpdate()),
        l -> writeLog(l.getErrorMessage())
);
```

NOPと比べるとはるかに安全で、洗練されている感じがすると思いませんか？

## NOPが一番適する状況はないのか？
一度話をNOPに戻します。

NOPは同一視をして成功と失敗に同じ命令をし、勝手に異なる振る舞いをしてもらうのが得意です。

ですが、失敗って振る舞うのでしょうか？
僕はそこがいまいち腹落ちしていません。

例えば「会員の月額料金を計算する、プレミアムオプションの契約が有ったり無かったりする」と言うのを考えてみます。
![PremiumMember.png](https://qiita-image-store.s3.amazonaws.com/0/113398/48a90acf-ae12-6cc5-6a3e-310b6195b339.png)

とても綺麗に実装できそうですが、`NoPremiumOptionMember`は果たして失敗でしょうか？
この2つの具象クラスは成功のケース1とケース2だと思います。
（当然文脈には寄りますが...）

そしておそらく2つの具象クラスは少し振る舞いやステータスが違う程度なのでしょうから、例えばDB保存もどちらも出来そうです。
その点においてもこの例は「成功と失敗」ではなく「成功1と成功2」であると考えられます。

あからさまな失敗としては、料金計算をしようとしているのに会員自体が存在しない様な場合でしょうか？
![Member.png](https://qiita-image-store.s3.amazonaws.com/0/113398/63477506-548d-f130-28d6-494031fc9cd4.png)

ですが、`NonexistentMember`の`calMonthlyFee()`は何を返すべきでしょうか。
`void`なら空振りで済みますが、`int`は返せません。

ですので、僕には「成功と失敗と言う事なる結果を区別せずに同一視するが、それらが明確に成功と失敗である状況」が思いつけません。

前者の例は成功と失敗ではない適切な切り口で抽象化を行いストラテジパターンと捉えるべきであり、後者の例は型チェックやキャストが必ず必要になってしまいそうです。

上記の理由により、僕にはNOPが最良の選択となる状況が想定できません。

## まとめ
### NOPに対しての持論
+ クラス・コードを増やしてもぬるぽがキャスト例外になるだけ（になりやすい）
+ 成功と失敗は対の関係であるが、NOPの実現手段が同列の関係を扱うストラテジパターンであるため「失敗の表現」としては不適切
+ 片方でしか必要ない処理を用意する場合、もう片方は空振りを定義させられるため同量の無駄なメソッドが出来る
+ ストラテジパターンではなくて本当に対関係である成功と失敗であれば、同一視してしまえるinterfaceは用意してはいけない
+ NOPを用いている箇所は、以下のどちらかに発想を遷移させるのが適切
  + 具象クラスの関係が同一視であれば、適切な抽象化を行いストラテジパターンにする
  + 具象クラスの関係が対の関係であれば、interfaceを無くしEitherを用いる
+ そもそももう古いし、もっと良い工夫が積み重ねられているはず
  + JavaにOptionalすら無かった頃の工夫だし

成功と失敗とは同列に扱える物では無いのではないか？
だがNOPはinterfaceを用いてその2つを抽象的に同じ物としてしまっている。

### Eitherに対しての持論
+ 異なるクラスを成功と失敗として扱える
+ キャストを用いるNOPよりは型安全だと思う
  + しかし必ずしも全く実行時例外が発生しないわけではない
  + 大抵の場合`getRight()`の様なメソッドがあり、失敗時にそれを叩くと実行時例外は起きてしまう
+ 言語によってはEither自体が用意されていなかったりする
+ （余談）ApplicativeやMonadまで用意されている言語だと、驚くくらい強力でコードが簡潔
  + 詳細は最後のおまけで

Eitherは成功と失敗を別のものとして扱える。

以上が「失敗を表現する手法としてNullObjectパターンが不適切でEitherが適切だと思う理由」です。

## おまけ
+ HaskellでのEither（だけではないですが）の記事を書いています、Eitherに興味が湧いたらHaskellのEitherが超凄いのでぜひ
  + [HaskellのFunctorとApplicativeFunctorとMonad](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3)
  + [HaskellのData.Either.Validationを使う](http://qiita.com/suzuki-hoge/items/5178acebb020bc8a519b)
  + Eitherの恩恵はこれらのサポートがあるかで大分違ってくる（と思っている）
