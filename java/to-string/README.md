Java と Groovy のアノテーションによる ToString の挙動まとめ

## これは？
仕事は`src.main`が`Java`、`src.test`が`Groovy`なんだけど、ちょっと別要件で`src.main`を`Groovy`で書いたら`@ToString`まわりでハマったのでまとめメモ
果たしてどれくらい意味があるまとめかは不明

`Groovy`でクラス作って動かして`AOP`でターミナルとログファイルに変数を出力しながら使うシステムなんだけど、全然ちゃんと`ToString`られてなかったので調べてみた

## Java
`Java`には`@lombok.ToString`というアノテーションがある（要`lombok`）

```Java:lombok.ToString
public @interface ToString {
	boolean includeFieldNames() default true;

	String[] exclude() default {};

	String[] of() default {};

	boolean callSuper() default false;

	boolean doNotUseGetters() default false;
}
```

ソースの`javadoc`の部分を除いた抜粋だけど、要点は上の設定項目

### Class
普通は`import`して使うけど、今回は明示したいのと掲載コード行を減らすために`@lombok.ToString`みたいに書く

#### 1 アノテーションなし
こんなのだれが見たいんだ

```Java
public class FooId1 {
    private final String value = "1234";
}
// to_string.j.c.FooId1@27c170f0
```

#### 2 ただ付ける
楽だし、状況次第ではこれで十分

```Java
@lombok.ToString
public class FooId2 {
    private final String value = "1234";
}
// FooId2(value=1234))
```

#### 3 フィールド名を無くす
後で例をだすけど、入れ子が多いクラス構造だとこっちの方が良い

```Java
@lombok.ToString(includeFieldNames = false)
public class FooId3 {
    private final String value = "1234";
}
// FooId3(1234)
```

#### 4 アクセッサがあると使われる
手書きして変なアクセッサ書くことはまずないけど、事故りそうだし小ネタとして掲載

```Java
@lombok.ToString
public class FooId4 {
    private final String value = "1234";

    public String getValue() {
        return "5678";
    }
}
// FooId4(value=5678)
```

#### 5 アクセッサを使わせない
一応こう書いておけば事故は防げる

```Java
@lombok.ToString(doNotUseGetters = true)
public class FooId5 {
    private final String value = "1234";

    public String getValue() {
        return "5678";
    }
}
// FooId5(value=1234)
```

#### 2' 2の例の入れ子
ただ付けた場合、個人的には冗長

```Java
@lombok.ToString
public class Foo2 {
    private final FooId2 id = new FooId2();
    private final FooName2 name = new FooName2();
}
// Foo2(id=FooId2(value=1234), name=FooName2(value=John Doe))
```

#### 3' 3の例の入れ子
`Java`のクラスでは、これが個人的には一番良い

```Java
@lombok.ToString(includeFieldNames = false)
public class Foo3 {
    private final FooId3 id = new FooId3();
    private final FooName3 name = new FooName3();
}
// Foo3(FooId3(1234), FooName3(John Doe))
```

### Enum
一応`Enum`も確認しておいた

#### 1 アノテーションなし
`Enum`はこれで良い

```Java
public enum FooStatus1 {
    APPLYING, NOT_APPLYING
}
// NOT_APPLYING
```

#### 2 ただ付ける
クラス名が出るのは良いんだけど、肝心な部分が含まれない

```Java
@lombok.ToString
public enum FooStatus2 {
    APPLYING, NOT_APPLYING
}
// FooStatus2()
```

## Groovy
`Groovy`には`@groovy.transform.ToString`というアノテーションがあり、こちらは言語が用意している

```Java:lombok.ToString
public @interface ToString {
    String[] excludes() default {};

    String[] includes() default {};

    boolean includeSuper() default false;

    boolean includeSuperProperties() default false;

    boolean includeNames() default false;

    boolean includeFields() default false;

    boolean ignoreNulls() default false;

    boolean includePackage() default true;

    boolean cache() default false;
}
```

同じく設定項目だけ抜粋

### Class
`Groovy`は色々試すまでさっぱり分からなかった

#### 1 アノテーションなし
同じく、これに需要はない

```Groovy
class FooId1 {
    private final String value = '1234'
}
// to_string.g.c.FooId1@3159c4b8
```

#### 2 ただ付ける
値出てないんですけど！？
実質何も変わってないよね？？

```Groovy
@groovy.transform.ToString
class FooId2 {
    private final String value = '1234'
}
// to_string.g.c.FooId2()
```

#### 3 public にしてみる
`private`が悪いかと思い、仕方なく`public`にしてみるが解決しない

```Groovy
@groovy.transform.ToString
class FooId3 {
    public final String value = '1234'
}
// to_string.g.c.FooId3()
```

#### 4 アクセス修飾子を外す
なぜか解決した
が、`private`としたい

```Groovy
@groovy.transform.ToString
class FooId4 {
    final String value = '1234'
}
// to_string.g.c.FooId4(1234)
```

#### 5 フィールドを含むと明示する
色々見ていたらフィールドはデフォルトだと含まないらしい

```Groovy
@groovy.transform.ToString(includeFields = true)
class FooId5 {
    private final String value = '1234'
}
// to_string.g.c.FooId5(1234)
```

#### 6 フィールド名を含む
含むことも出来る

```Groovy
@groovy.transform.ToString(includeFields = true, includeNames = true)
class FooId6 {
    private final String value = '1234'
}
// to_string.g.c.FooId6(value:1234)
```

#### 7 FQCN を含めない
ある程度の規模でちゃんとパッケージ構成を考えていると、FQCN があると長くなりすぎるので消したい

```Groovy
@groovy.transform.ToString(includeFields = true, includePackage = false)
class FooId7 {
    private final String value = '1234'
}
// FooId7(1234)
```

#### 6' 6の例の入れ子
`FQCN`とフィールド名があると長すぎるかな

```Groovy
@groovy.transform.ToString(includeFields = true, includeNames = true)
class Foo6 {
    private final FooId6 id = new FooId6()
    private final FooName6 name = new FooName6()
}
// to_string.g.c.Foo6(id:to_string.g.c.FooId6(value:1234), name:to_string.g.c.FooName6(value:Jane Doe))
```

#### 7' 7の例の入れ子
`Groovy`のクラスでは、これが個人的には一番良い

```Groovy
@groovy.transform.ToString(includeFields = true, includePackage = false)
class Foo7 {
    private final FooId7 id = new FooId7()
    private final FooName7 name = new FooName7()
}
// Foo7(FooId7(1234), FooName7(Jane Doe))
```

### Enum
`Enum`に関しては`Java`と全く同じ

#### 1 アノテーションなし
`Enum`はこれで良い

```Java
public enum FooStatus1 {
    APPLYING, NOT_APPLYING
}
// NOT_APPLYING
```

#### 2 ただ付ける
クラス名が出るのは良いんだけど、肝心な部分が含まれない

```Java
@lombok.ToString
public enum FooStatus2 {
    APPLYING, NOT_APPLYING
}
// FooStatus2()
```

## まとめ
### 対応表
対応してそうな部分だけ整理

項目                 | Java                                    | Groovy                               | 備考                                              
:--                  | :--                                     | :--                                  | :--                                               
フィールド名         | `includeFieldNames()`<br>`default true` | `includeNames()`<br>`default false`  | 逆だ                                              
フィールドを一部含む | `of()`<br>`default {}`                  | `includes()`<br>`default {}`         | この項目を指定する予定がないので<br>実例は省略した
フィールドを一部除く | `exclude()`<br>`default {}`             | `excludes()`<br>`default {}`         | 同上                                              
継承時の挙動         | `callSuper()`<br>`default false`        | `includeSuper()`<br>`default false`  | 継承をしないので、実例は省略した                  
FQCN                 | 出ない                                  | `includePackage()`<br>`default true` | ある意味逆                                        

`@groovy.transform.ToString`にはまだ項目があるが、対応する`@lombok.ToString`の項目がないし今は興味も無いので省略する

### Java 再掲
`Class`は`Foo`と同じ指定方法、`Enum`にはアノテーションなしで統一

```Java
@lombok.ToString(includeFieldNames = false)
public class Foo {
    private final FooId id = new FooId();
    private final FooName name = new FooName();
    private final FooStatus fooStatus = FooStatus.NOT_APPLYING;
    private final BarStatus barStatus = BarStatus.NOT_APPLYING;
}
// Foo(FooId(1234), FooName(John Doe), NOT_APPLYING, NOT_APPLYING)
```

一番スッキリと要点だけが表示されると思う

### Groovy 再掲
同じく`Class`は`Foo`と同じ指定方法、`Enum`にはアノテーションなしで統一

```Groovy
@groovy.transform.ToString(includeFields = true, includePackage = false)
class Foo {
    private final FooId id = new FooId()
    private final FooName name = new FooName()
    private final FooStatus fooStatus = FooStatus.NOT_APPLYING
    private final BarStatus barStatus = BarStatus.NOT_APPLYING
}

// Foo(FooId(1234), FooName(Jane Doe), NOT_APPLYING, NOT_APPLYING)
```

まったく同じに出来た！

## おまけ
### Groovy の Class に @lombok.ToString を使う
いつもは`Java`でクラス作るんだけど、`Groovy`でクラス作ってアノテーションの部分だけ`java`からコピーして持ってきたら混ざっちゃった

結論から言うと無意味

```Groovy
@lombok.ToString
class FooId1 {
    private final String value = '1234'
}

// to_string.r.g.FooId1@29ca901e
```

### Java の Class に @groovy.transform.ToString を使う
逆は起き得ないと思うけど、一応やってみた

結論から言うとやはり無意味

```Java
@groovy.transform.ToString
public class FooId1 {
    private final String value = "1234";
}

// to_string.r.j.FooId1@27c170f0
```

### Java のアノテーションの配列指定の仕方
これは`@ToString`と言うよりはアノテーション全般の話なのかな？

`Java`だと`{x, y, ...}`と指定する
これは知っていた

```Java
@lombok.ToString(includeFieldNames = false, of = {"spam", "egg"})
public class Python {
    private final String spam = "spam";
    private final String ham = "ham";
    private final String egg = "egg";
}
// Python(spam, egg)
```

+ 間違えがち(?)だけど、`["spam", "ham"]`ではない
  + これは`InelliJ`なら赤線出るからすぐ気づける
+ `{"spam"}`は`"spam"`と書ける
  + これは略記の話

### Groovy のアノテーションの配列指定の仕方
これが最初わからなくて、`groovy.transform.ToString`のアクセス修飾子の挙動も相まってとても混乱した

`Groovy`だと`[x, y, ...]`と指定する

```Groovy
@groovy.transform.ToString(includePackage = false, includes = ['spam', 'egg'])
class Python {
    private final String spam = 'spam'
    private final String ham = 'ham'
    private final String egg = 'egg'
}
// Python()
```

...！？
何も警告されてないのに、全然ダメな感じなんだけど何これ！

ってとてもハマったけど、今思うと`includeFields = true`が無いからだね
こんだけまとめたからすぐ理解できる様になってる自分がちょっと面白いｗ

`includes`を指定しても`includeFields`立てないと意味ないのかよ！！分かりづらい！！！

ちなみに、`includes = 'spam,egg'`とかいう謎の記法もアリらしい
これって`@groovy.transform.ToString`のルール？`Groovy`のルール？

### Groovy の private フィールド
実は`Groovy`の`private`はほぼ無意味
なので`private`を外してただ`@groovy.transform.ToString`を付けるだけでも実はまぁまぁ良かったりする

ちょっと一旦`@groovy.transform.ToString`からは離れて、`private`の挙動の整理

```Groovy
class Bar {
    String v1 = 'v1'
    public String v2 = 'v2'
    private String v3 = 'v3'
    static String v4 = 'v4'
    static public String v5 = 'v5'
    static private String v6 = 'v6'
}
```

こんなクラスを書いて

![スクリーンショット 2017-07-01 21.25.57.png](https://qiita-image-store.s3.amazonaws.com/0/113398/1b120a8a-0e6d-9d52-676a-b6a7319b1ac8.png)

こんな風に書くと、アクセス出来ちゃう

けど、`IntelliJ`だと補完対象にされないし無理矢理書いても警告が出るので、一応`private`と書いておきたい

![スクリーンショット 2017-07-01 21.24.23.png](https://qiita-image-store.s3.amazonaws.com/0/113398/7ff691b1-004a-a791-e454-07c93be937d1.png)
![スクリーンショット 2017-07-01 21.25.21.png](https://qiita-image-store.s3.amazonaws.com/0/113398/50fc49f3-9c3c-c6f0-3dc5-d90aa86e2cf1.png)

`v3`と`v6`は補完候補に出てこないし、書いても`v3`と`v6`はちょっと黄ばんでいるね！
ありがとう`IntelliJ`！

[参考](https://issues.apache.org/jira/browse/GROOVY-1875)

### 実は Enum の結果に不満
まとめのところで再掲した様に、同じ要素名を持つ`Enum`が並ぶとやや分かりづらくなってしまう

```
// Foo(FooId(1234), FooName(John Doe), NOT_APPLYING, NOT_APPLYING)
```

もし`APPLYING, NOT_APPLYING, APPLYING`とか並ぶと「ん？2つめってなんだっけ？」ってなることがある

なので理想は下みたいになることなんだけど、どうもうまくいかなかった

```
// Foo(FooId(1234), FooName(John Doe), FooStatus.NOT_APPLYING, BarStatus.NOT_APPLYING)
```

こんなん書いたらできるけどねー
手書きはしたくないよねー

```Java
public enum BazStatus {
    APPLYING, NOT_APPLYING;

    @Override
    public String toString() {
        return getClass().getSimpleName() + "." + name();
    }
}
// BazStatus.NOT_APPLYING
```

`@ToString`以外でも色々と小さい不満があるのでアノテーション作りたいんだけど、こういうコードを生み出す系のアノテーションってどうやって作るんだろう
内容次第では`InelliJ`プラグインも必要になるし、オレオレならまだしも仕事でチームで使うのは難しいよなー

### MetaClass が混じる
そういえばこのまとめ中見なかったので忘れていたけど、仕事中に対応した時はなんかそんなのが`@groovy.transform.ToString`した結果に混じっていた
けどただの`FQCN`付きのハッシュで無駄に長いし自分で設定してないので中身に興味も無いので、邪魔だった

それで`includes`の調査をしたんだったかな
アクセス修飾子、`includeFields`、`includes`、配列指定を一気に組み合わせちゃいながら確認したから混乱してしまった

おしまい
