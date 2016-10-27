Java8のStreamの終端操作で任意の関数を実行する

どうも、仕事でJavaを書いている者です。

`Stream`使ってますか？便利ですよね、特に毎度毎度`.collect(Collectors.toList())`とかやるところがイカしてますよね。

毎度そんな面倒な記述を要求するなら、もっと柔軟に色んなことしたァァァァ〜〜ィィィってイラッと来たので
`.collect()`の部分で任意の関数を実行する方法を考えてみました。

## 予備知識
Java8の関数インターフェースを知らないと辛いかも

この記事では以下と、`Bi`が付くインターフェースが出てきます（`Bi`が付いたら引数が2つになる感じ）

インターフェース | 引数 | 戻り
:--              | :--  | :-- 
Function\<T, R\> | T    | R   
Supplier\<T\>    | なし | T   
Consumer\<T\>    | T    | なし

[java.util.function以下の関数インターフェース使い方メモ](http://qiita.com/opengl-8080/items/22c4405a38127ed86a31) がとても参考になります。

あとジェネリクス
`super`とか`extends`とかは出てこないので、`Function<T, T>`なら引数も戻りも同じ型なんだなー、くらいがわかれば十分

## 想定するシチュエーション
### クラス構成
`Book`というクラスがあり、それを複数扱う際には`List<Book>`ではなく`Books`クラスを用いる。
集合に対するロジックを`Books`クラスに集約するという、まぁOOP的な考え方。

```Java
public class Books {
    private final List<Book> values;
}
```

```Java
public class Book {
    private final Id id;
    private final Name name;
}
```

```Java
public class Id {
    private final Integer value;
}
```

```Java
public class Name {
    private final String value;
}
```

（コンストラクタやゲッターは省略してます、`lombok`でも使ってちょ）

別に違うシチュエーションでも応用は利くけど、これが職場で一番多いのでこれにした。

### 処理イメージ
処理の中で`List<Name>`が複数手に入り、その`Name`を基に`Book`を生成する。
当然`Book`は複数出来るので`List<Book>`が出来るのだが、それを更に`Books`に変換する。

```Java
List<Name> names = Arrays.asList(new Name("foo"), new Name("bar"));

List<Book> bookList = names.stream()
        .map(name -> new Book(Id.allocate(), name))
        .collect(Collectors.toList());

Books books = new Books(bookList);
```

一時変数が無いならこうでも良い

```Java
Books books = new Books(
    names.stream()
            .map(name -> new Book(Id.allocate(), name))
            .collect(Collectors.toList())
);
```

要は`List<Book>`を経由するのがダルいので、`Stream`の終端操作（`.collect()`）で`Books`を作ってしまおう、という発想。

## java.util.stream.Collectors.toList() の実装の写経
前置きが長かったけど、とりあえず`Collectors.toList()`の実装を写経してみた
（こちらもコンストラクタとゲッターは省略してます）

なんか`Collector<T, A, R>`を実装したクラスを返せば良いらしい。

```Java
public class MyCollector<T, A, R> implements Collector<T, A, R> {
    private final Supplier<A> supplier;
    private final BiConsumer<A, T> accumulator;
    private final BinaryOperator<A> combiner;
    private final Function<A, R> finisher;
    private final Set<Characteristics> characteristics;

    public static <T> MyCollector<T, ?, List<T>> toList() {
        return new MyCollector<>(
                (Supplier<List<T>>) ArrayList::new,
                List::add,
                (left, right) -> { left.addAll(right); return left; },
                Function.identity(),
                Collections.unmodifiableSet(EnumSet.of(Characteristics.IDENTITY_FINISH))
        );
    }
}
```

カンと雰囲気だけでテキトーーに読む

まず`<T, A, R>`の整理から。

`R`は当然`List<Book>`で確定する。

次に`T`だけど、`T, R`が`toList()`に限っては`T, List<T>`の関係だから、`T`は`Book`だよね。

`A`は何だろ？
`A`は`Function<A, R>`の部分が`Function.identity()`だから`A`と`R`は同じ、つまり`A`も`List<T>`ってことだよね。
（`identity()`は`何もしない`。実装を見ればすぐわかる。`return t -> t;`だけだから。）

だから`Book`に対しての`toList()`に具体化して言えば、`<T, A, R>`は`<Book, List<Book>, List<Book>>`のはず！

そう考えると、5つのフィールドのうち、`A`と`R`を使う`Function<A, R> finisher`にだけ注目すれば良いんじゃあないかな？
求める改造結果は`<Book, List<Book>, Books>`だから、`T`, `A`はそのまま使わせてもらう！

（ちなみに、`A`の部分はなんか処理用の中間生成物みたいなイメージっぽい）

一応なんとなくフィールドの意味を（型だけで）察してみる

```Java
定: Supplier<A> supplier;

値: (Supplier<List<T>>) ArrayList::new
```
`Book`の足し込み先`List<Book>`を用意する方法かな？

```Java
定: BiConsumer<A, T> accumulator;

値: List::add
```
`Book`ひとつを`List<Book>`に突っ込む方法かな？

```Java
定: BinaryOperator<A> combiner;

値: (left, right) -> { left.addAll(right); return left; }
```
並行処理のため？`A`を2つ作ってがっちゃんする、みたいなことをしているらしい？
（`BinaryOperator<A>`は`BiFunction<A, A, A>`と同じ感じなので、`left`も`right`も`List<Book>`）

```Java
定: Function<A, R> finisher;

値: Function.identity()
```
多分名前の通り、出来上がった`A`を最後に`R`にする方法だよね？

```Java
定: Set<Characteristics> characteristics;

値: Collections.unmodifiableSet(EnumSet.of(Characteristics.IDENTITY_FINISH))
```
これは挙動を設定するのかな？内部実装が結構これ次第で条件分岐している気がした
`CONCURRENT`, `UNORDERED`, `IDENTITY_FINISH`の三種があり、複数の持ち方があるみたい

繰り返すけど、9割はカンです。
ただまぁやっぱり、`Function<A, R> finisher`をちょっと変えて、
`Set<Characteristics> characteristics`も別のを指定するだけで済みそうかな？

## MyCollector.create() の実装
```Java
public class MyCollector<T, A, R> implements Collector<T, A, R> {
    private final Supplier<A> supplier;
    private final BiConsumer<A, T> accumulator;
    private final BinaryOperator<A> combiner;
    private final Function<A, R> finisher;
    private final Set<Characteristics> characteristics;

    public static <T, R> MyCollector<T, ?, R> create(Function<List<T>, R> constructor) {
        return new MyCollector<>(
                (Supplier<List<T>>) ArrayList::new,
                List::add,
                (left, right) -> { left.addAll(right); return left; },
                constructor,
                Collections.emptySet()
        );
    }
```

ま、散々前置きしておいてこれだけだった

`toList()`では`R`は`List<T>`だったけど、当然こちらでは`T`でも`A`でもないので`R`のまま

そして`finisher`の部分は外から渡せる様にした。当然型は`Function<List<T>, R>`だ！

`characteristics`は`A`と`R`が異なる別の実装は`空Set`だったので、なんとなく真似てみた。
（例えば`A` -> `String`の`joining()`とか）

## 利用例
```Java
Books books = names.stream()
        .map(name -> new Book(Id.allocate(), name))
        .collect(MyCollector.create(Books::new));
```

ちょっとスッキリしたでしょ！満足！

## おまけ
実は`Collectors`を読んでいるときに、こんなのを発見した

```Java
public static<T,A,R,RR> Collector<T,A,RR> collectingAndThen(
        Collector<T,A,R> downstream,
        Function<R,RR> finisher
) {
```

これ、まさにじゃねｗ

中読んだら第一引数の`finisher`に更に渡した`finisher`を関数合成してくれてる！
（こんな感じ `downstream.finisher().andThen(finisher)`）

まさにそれだったｗ　長くなりそうだけどｗ

```Java
Books books = names.stream()
        .map(name -> new Book(Id.allocate(), name))
        .collect(Collectors.collectingAndThen(Collectors.toList(), Books::new));
```

いやー、終端操作って最後に関数実行してくれるんだねー（棒）
使い方日本語で調べる前に中をざーっとでも読もうねーってことだよねー（棒）

でもこれ使えば色々出来るね、知れただけでも収穫。

おしまい ﾉｼ
