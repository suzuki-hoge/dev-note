Streamの終端操作で色々する

どうも、[Java8のStreamの終端操作で任意の関数を実行する](http://qiita.com/suzuki-hoge/items/6c5e25eaf48160c1fedf)を書いた者です。

`Stream`使ってますか？たまりませんよね？特に`Stream`の`last`とかも用意されてないところがイカれてますよね？
`last()`なんか自分で実装するとは思わなかったよ！リファレンスを2度見しちゃったよ！

## 前置き
[前回の最後](http://qiita.com/suzuki-hoge/items/6c5e25eaf48160c1fedf#%E3%81%8A%E3%81%BE%E3%81%91)に`Collectors#collectingAndThen`と言うのを見つけたんだけど、
その後色々な事を`Stream`の終端操作で済ませたくなったので`ListUtil`ってのを作って色々書いてみたよ！

今回は自前で`Collector<T, A, R>`の実装をせずに、全てを`Collectors#collectingAndThen`で済ませる方針だよ！

### ListUtil
```Java
public class ListUtil {
}
```

というクラスに色々なメソッドを用意していくよ！
メソッドは`Collector<T, A, R>`的な何かを返すので`Stream#collect`で使う感じだよ！

ちょっと流れのIn/Outがわかりづらいけど、`R`に相当する部分が戻りだと理解すると読めるよ！

### domain
一部のサンプルで適当なクラスを用いるので用意したドメインクラスを載っけておくよ！
（例によってコンストラクタ等は略しているよ！`lombok`でも使ってね！）

適当なクラス

```Java
public class Book {
    private final String name;
}
```

適当なクラスのリストクラス

```Java
public class BookList {
    private final List<Book> values;
}
```

適当なフィールドを持つリストクラス

```Java
public class NamedBookList {
    private final String listName;
    private final List<Book> values;
}
```

## Listに対して任意の変換を行う
### Listを別の型に変換する
[Java8のStreamの終端操作で任意の関数を実行する](http://qiita.com/suzuki-hoge/items/6c5e25eaf48160c1fedf)に投稿したコードと結果は同じ

#### construct
```Java
public static <T, R> Collector<T, ?, R> construct(Function<List<T>, R> constructor) {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            constructor
    );
}
```

#### test
```Java
@Test
public void test() {
    BookList exp = new BookList(
            Stream.of(new Book("foo"), new Book("bar"))
                    .collect(Collectors.toList())
    );

    BookList act = Stream.of(new Book("foo"), new Book("bar"))
            .collect(ListUtil.construct(BookList::new));

    assertEquals(exp, act);
}
```

### Listを別の型に変換する List以外の引数あり
仕事のコードでListの他に1つフィールドを持つリストクラスが多いので用意した

#### constructWith
```Java
public static <Some, T, R> Collector<T, ?, R> constructWith(Some some, BiFunction<Some, List<T>, R> constructor) {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            list -> constructor.apply(some, list)
    );
}
```

#### test
```Java
@Test
public void test() {
    NamedBookList exp = new NamedBookList(
            "sample books",
            Stream.of(new Book("foo"), new Book("bar"))
                    .collect(Collectors.toList())
    );

    NamedBookList act = Stream.of(new Book("foo"), new Book("bar"))
            .collect(ListUtil.constructWith("sample books", NamedBookList::new));

    assertEquals(exp, act);
}
```

## Listの要素を取り出す
### 先頭１件を取得
空リストだった場合は実行例外

#### head
```Java
public static <T> Collector<T, ?, T> head() {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            list -> getOrThrow(list, 0)
    );
}

private static <T> T getOrThrow(List<T> list, int n) {
    if (list.size() == 0) {
        throw new RuntimeException("list is empty");
    }
    return list.get(n);
}
```

#### test
```Java
@Test
public void test() {
    int exp = 4;

    int act = Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.head());

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    thrown.expect(RuntimeException.class);
    thrown.expectMessage("list is empty");

    Stream.empty()
            .collect(ListUtil.head());
}
```

### 末尾１件を取得
例外の仕様や`private`メソッド、およびテストは`head`と同様のため省略

#### last
```Java
public static <T> Collector<T, ?, T> last() {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            list -> getOrThrow(list, list.size() - 1)
    );
}
```

#### test
```Java
@Test
public void test() {
    int exp = 3;

    int act = Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.last());

    assertEquals(exp, act);
}
```

### 先頭１件をOptionalに包んで取得
なぜかこれだけは`Stream#findFirst`として存在する

#### headOpt
```Java
public static <T> Collector<T, ?, Optional<T>> headOpt() {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            list -> getOpt(list, 0)
    );
}

private static <T> Optional<T> getOpt(List<T> list, int n) {
    if (list.size() == 0) {
        return Optional.<T>empty();
    } else {
        return Optional.of(list.get(n));
    }
}
```

#### test
```Java
@Test
public void test() {
    Optional<Integer> exp = Optional.of(4);

    Optional<Integer> act = Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.headOpt());

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    Optional<Integer> exp = Optional.empty();

    Optional<Integer> act = Stream.of(4, 2, 5, 1, 3)
            .filter(it -> it == 0)
            .collect(ListUtil.headOpt());

    assertEquals(exp, act);
}
```

### 末尾１件をOptionalに包んで取得
例外の仕様や`private`メソッド、およびテストは`headOpt`と同様のため省略

#### lastOpt
```Java
public static <T> Collector<T, ?, Optional<T>> lastOpt() {
    return Collectors.collectingAndThen(
            Collectors.toList(),
            list -> getOpt(list, list.size() - 1)
    );
}
```

#### test
```Java
@Test
public void test() {
    Optional<Integer> exp = Optional.of(3);

    Optional<Integer> act = Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.lastOpt());

    assertEquals(exp, act);
}
```

## 特定の制約の下でListの要素を取り出す
### 要素が１件の場合のみそれを取り出す
仕事のコードにおいて頻出するので書いてみた
複数の要素を`filter`をした結果がキッカリ１件になる事を期待している

#### exactlyOne
```Java
public static <T, E extends RuntimeException> Collector<T, ?, T> exactlyOne(Supplier<E> sup) {
    Function<List<T>, T> f = list -> {
        if (list.size() != 1) {
            throw sup.get();
        }

        return list.get(0);
    };

    return Collectors.collectingAndThen(
            Collectors.toList(),
            f::apply
    );
}
```

#### test
```Java
@Test
public void test() {
    int exp = 3;

    int act = Stream.of(4, 2, 5, 1, 3)
            .filter(it -> it == 3)
            .collect(ListUtil.exactlyOne(() -> new RuntimeException("must be just [3]")));

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    thrown.expect(RuntimeException.class);
    thrown.expectMessage("must be just [3]");

    Stream.of(4, 2, 5, 1, 3)
            .filter(it -> it == 0)
            .collect(ListUtil.exactlyOne(() -> new RuntimeException("must be just [3]")));
}
```

```Java
@Test
public void test() {
    thrown.expect(RuntimeException.class);
    thrown.expectMessage("must be just [3]");

    Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.exactlyOne(() -> new RuntimeException("must be just [3]")));
}
```

### 要素が２件未満の場合のみそれをOptionalに包んで取り出す
複数の要素を`filter`をした結果が１件以下になる事を期待している

`exactlyOne`とあわせて、DB参照結果が型的には`List<T>`で戻ってくるけど、仕様的に2件取れちゃってたら問題ある、なんて時に使えるかな

#### atMostOne
```Java
public static <T, E extends RuntimeException> Collector<T, ?, Optional<T>> atMostOne(Supplier<E> sup) {
    Function<List<T>, Optional<T>> f = list -> {
        if (list.size() >= 2) {
            throw sup.get();
        }

        return getOpt(list, 0);
    };

    return Collectors.collectingAndThen(
            Collectors.toList(),
            f::apply
    );
}
```

#### test
```Java
@Test
public void test() {
    Optional<Integer> exp = Optional.of(3);

    Optional<Integer> act = Stream.of(4, 2, 5, 1, 3)
            .filter(it -> it == 3)
            .collect(ListUtil.atMostOne(() -> new RuntimeException("must be [3] or []")));

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    Optional<Integer> exp = Optional.empty();

    Optional<Integer> act = Stream.of(4, 2, 5, 1, 3)
            .filter(it -> it == 0)
            .collect(ListUtil.atMostOne(() -> new RuntimeException("must be [3] or []")));

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    thrown.expect(RuntimeException.class);
    thrown.expectMessage("must be [3] or []");

    Stream.of(4, 2, 5, 1, 3)
            .collect(ListUtil.atMostOne(() -> new RuntimeException("must be [3] or []")));
}
```

## Listを整形する
### 任意の値でユニークにする
クラスの任意のフィールドでListをユニークにするために、要素を任意の値に変換するメソッドを受ける

#### distinctBy
```Java
public static <T, Key> Collector<T, ?, List<T>> distinctBy(Function<T, Key> toKey) {
    return Collectors.collectingAndThen(
            Collectors.groupingBy(toKey, LinkedHashMap::new, Collectors.toList()),
            map -> map.values().stream().map(list -> list.get(0)).collect(Collectors.toList())
    );
}
```

#### test
```Java
@Test
public void test() {
    List<Integer> exp = Arrays.asList(4, 2, 5, 1, 3);

    List<Integer> act = Stream.of(4, 4, 2, 5, 5, 5, 1, 3, 1)
            .collect(ListUtil.distinctBy(it -> it));

    assertEquals(exp, act);
}
```

```Java
@Test
public void test() {
    List<Book> exp = Arrays.asList(new Book("foo"), new Book("bar"));

    List<Book> act = Stream.of(new Book("foo"), new Book("bar"), new Book("foo"))
            .collect(ListUtil.distinctBy(Book::getName));

    assertEquals(exp, act);
}
```

## そういえば
今更言うのかって感じだけど、終端操作でやろうとしているのはネストだと読みづらいからです

でこぼこしたり上の行に戻ったりと、目線移動が変になるから読みづらいでしょ？

```Java
new SomeObject(
// 5
    Stream.filter.map.toList
//     1 --> 2 --> 3  -> 4
);
```

こんな風になってしまったらもう大変だよね？

```Java
headOpt(
        Stream.of(new Book("foo"), new Book("bar"), new Book("baz"))
                .filter(book -> book.name.equals("bar"))
                .map(book -> new Book(book.name + "2"))
                .collect(Collectors.toList())
).map(it -> it.name);
```

終端操作なら続けて書けるので上から下へ素直に読めるでしょ！

```Java
Stream.of(new Book("foo"), new Book("bar"), new Book("baz"))
        .filter(book -> book.name.equals("bar"))
        .map(book -> new Book(book.name + "2"))
        .collect(ListUtil.headOpt())
        .map(it -> it.name);
```

## まとめ
なんか何でも書けるので楽しくなって色々書いた！

問題は`ListUtil`を見た時にパッと見て戻りがわかりづらい点かなぁ
`Collector<T, A, R>`の`R`の部分が戻りだと理解すれば大丈夫なので、慣れ次第かな？

これで快適なJavaライフが送れるね！ 乙っしたﾉｼ

## 追伸
ちなみに冒頭で触れた`last`もないぜ！だけど、調べてみたらこんな例があったよ

```Java
stream.reduce((first, second) -> second);
```

なるほど！！！
