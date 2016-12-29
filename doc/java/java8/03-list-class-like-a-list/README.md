自前のリストクラスのコードを削減する

どうも、[Java](http://qiita.com/suzuki-hoge/items/6c5e25eaf48160c1fedf)の[Stream](http://qiita.com/suzuki-hoge/items/fb662ec2ba32747d5a2c)について投稿していたらだんだん楽しくなってきたものです。

# はじめに
## リストクラスとは
リストクラス作ってますか？リストクラスと言ってもコレクションの拡張ではなくて、集約クラスとして便宜上そう呼んでいる物です。
「求めるな、命じよ」を実現するために集約は`List<T>`ではなくそれ専用のクラスを用意するという方針で仕事コードを書いています。

```Java
// 求める例 利用側が中身の実状に詳しい

List<Item> items = Arrays.asList();

List<Item> news = items
        .stream()
        .filter(item -> item.state == State.NEW)
        .collect(Collectors.toList());

List<Item> used = items
        .stream()
        .map(item -> new Item(item.name, State.USED))
        .collect(Collectors.toList());
```

```Java
// 命じる例 詳しいことは知らないけど命じるだけ

Items items = Items.empty();

Items news = items.pickNews();

Items used = items.toUsed();
```

`stream` -> `map/filter` -> `toList`の一連の流れにメソッド名を付けて集約クラスに押し込めることが出来るので
「言語上必要だから書いているコードを減らし」「適切な名前を付けることで業務ロジックだけを目立たせる」ことが出来ます。

また、「空の状態で生成する」とか「新品判定は`State.NEW`で行う」とか「中古状態とは`State`が`USED`である」とか言う`Item`クラスの都合を
`Item`クラス、および`Items`クラスから一切外に漏らさずカプセル化することが出来ています。

これにより「新品判定の仕様が変わったり」「中古状態は更に名前に`Sold`が付く」とか言う仕様変更時にも
修正するクラスを1箇所にすることが出来ます。

## リストクラスの中身
当然ですが、押し込めているだけなので`Items`クラスの中身のコード量自体は減っていません。
`Items`クラスを開けば`stream()`とか`.collect(Collectors.toList())`とか`new Items(`とかずらずら書いてあるわけです。

この記事はそのJavaを書く上でなくせないけど、「仕様上の意味は特に持ってないコードを削減する」ことを試みる記事です。
それにより極力「業務ロジックの読み書きに集中できるコードにする」ことが目的です。

# サンプルコード用クラス
例によってコンストラクタ等は省略しています（実際には`lombok`を使っています）
（上で使った`Items/Item`ではなくてすいません...）

```Java:Contract
public class Contract {
    private final UserId userId;
    private final Plan plan;

    public boolean isPremium() {
        return plan.isPremium();
    }

    // 自身の状態を更新する様なメソッド
    // ただ Immutable object としているので、新たなインスタンスを作って返している
    public Contract toNormal() {
        return new Contract(userId, Plan.NORMAL);
    }
}
```

```Java:ContractList
public class ContractList {
    private final List<Contract> values;
}
```

# 素のコードとリファクタリングしてみたコードの比較
今後`Contracts`を`ListClass`、`Contract`を`ElementClass`とします

## 生成
そもそもリストを作るのが面倒ってパターンが大半です

### `List<ElementClass>` -> `ListClass`
ちなみに、今後出てくる変数`constracts`はここで作ったものと同じ値だと思ってください

```Java:plain
ContractList contracts = new ContractList(
        findAll()
                .collect(Collectors.toList())
);
```

前に投稿した[ListUtil#construct](http://qiita.com/suzuki-hoge/items/fb662ec2ba32747d5a2c#construct)を使う
これ気に入ったのｗ

```Java:refactored
ContractList contracts = findAll()
        .collect(ListUtil.construct(ContractList::new));
```

### `[]` -> `ListClass`
空リストから生成することもあるよね

```Java:plain
ContractList empty = new ContractList(
        Collections.emptyList()
);
```

`ListClass`に`empty()`メソッドを用意してみる

```Java:ContractList
public class ContractList {
    // 色々略

    public static ContractList empty() {
        return new ContractList(Collections.emptyList());
    }
}
```

```Java:refactored
ContractList empty = ContractList.empty();
```

シンプルだし、`Stream.empty()`や`Optional.empty()`とも雰囲気があう
空リストの作り方もぶれない（`Arrays.asList()`とかでも動くけど）から生成は`ListClass`にやらせる方が良いよね

### `ElementClass` -> `List<ElementClass>` -> `ListClass`
単一の`ElementClass`をただリストにして`ListClass`にするパターン
地味に必要になるんだけど、思いの外妙に面倒なのがこれ

長いだろ...

```Java:plain
ContractList singleton = new ContractList(
        Collections.singletonList(
                new Contract(new UserId("001"), Plan.NORMAL)
        )
);
```

いまいち良く実装できなかったけど、`empty()`と似た発想で`ElementClass`にやらせるのが良いかな

```Java:Contract
public class Contract {
    // 同じく色々略

    public ContractList toList() {
        return new ContractList(Collections.singletonList(this));
    }
}
```

```Java:refactored
ContractList singleton = new Contract(new UserId("001"), Plan.NORMAL).toList();
```

## Stream
集合なんだし`stream`処理したいよね

ということでそれらのコードを削減するために`ListOf<ListClass, ElementClass>`という`interface`を作ってみました
実装しないと行けないメソッドは`getValues()`だけです

こんな感じで実装します
書くべき事はとても少なく出来ました（`lombok`使っていれば`values`に`@Getter`付けるだけ！）

```Java:ContractList
public class ContractList implements ListOf<ContractList, Contract> {
    @Getter
    private final List<Contract> values;
}
```

```Java:ListOf
public interface ListOf<ListClass, ElementClass> {
    public List<ElementClass> getValues();

    public default Stream<ElementClass> stream() {
        return getValues().stream();
    }

    public default <AnotherListClass, AnotherElementClass> AnotherListClass map(
            Function<ElementClass, AnotherElementClass> mapper,
            Function<List<AnotherElementClass>, AnotherListClass> constructor
    ) {
        return stream().map(mapper).collect(ListUtil.construct(constructor));
    }

    public default ListClass filter(
            Predicate<ElementClass> predicate,
            Function<List<ElementClass>, ListClass> constructor
    ) {
        return stream().filter(predicate).collect(ListUtil.construct(constructor));
    }
}
```

以降のリファクタリングしたコードはこれを使用しています

### `ListClass` -> `Stream<ElementClass>`
中身出しちゃうので何でもされ得てしまう...

```Java:plain
contracts.getValues().stream();
```

ただのエイリアスって感じだけど、カプセル化の観点から○

```Java:refactored
contracts.stream();
```

### `ListClass` --map--> `AnotherListClass`
`map`した結果型が変わるパターン

だんだんと文字数と行数が多くなってきた...
実ロジックは3行目だけなのに、5行もある...

```Java:plain
UserIdList userIds = new UserIdList(
        contracts.getValues().stream()
                .map(Contract::getUserId)
                .collect(Collectors.toList())
);
```

`stream()`を設けた発想の延長で、`map()`も直接`ListClass`に設けてみた
そして`map()`の第2引数に変換後のクラスまで教えてあげてみたら、こうなった

```Java:refactored
UserIdList userIds = contracts
        .map(Contract::getUserId, UserIdList::new);
```

### `ListClass` --filter--> `ListClass`
`filter`は型は変わらない点を除けば`map`とほぼ同じ
やりたいことは1行だけなのに5行必要なのも同じ

```Java:plain
ContractList premiums = new ContractList(
        contracts.getValues().stream()
                .filter(Contract::isPremium)
                .collect(Collectors.toList())
);
```

```Java:refactored
ContractList premiums = contracts
        .filter(Contract::isPremium, ContractList::new);
```

### `ListClass` --filter--> `ListClass` --map--> `ListClass`
当然連結もするだろう

```Java:plain
ContractList normals = new ContractList(
        contracts.getValues().stream()
                .filter(Contract::isPremium)
                .map(Contract::toNormal)
                .collect(Collectors.toList())
);
```

```Java:refactored
ContractList normals = contracts
        .filter(Contract::isPremium, ContractList::new)
        .map(Contract::toNormal, ContractList::new);
```

## 要素取得
ここは前回投稿ネタなのでおまけです
`ListUtil`も`ListOf`と同じく「業務ロジックに集中すること」を目的として書いたことを示す目的で載せてます

（ちゃんと実装してないけど）この例ではあるユーザの有効な契約を取得します
過去の無効な契約はいくつもあるけど、有効な契約は1つだけのはず、という架空仕様です
実際はただの`where句`の結合だからDB的にはいくつ取れるかわからないため、複数件戻すメソッドになっています

### `ListClass` -> `ElementClass`
あるユーザの有効な契約に対してなんらかの操作をするパターン
有効な契約があるはずという仕様に対して書かれたコード

```Java:plain
List<Contract> list = findEnablingBy(new UserId("001")).collect(Collectors.toList());

if (list.size() == 1) {
    Contract found = list.get(0);
} else {
    throw new RuntimeException("not be unique");
}
```

前に投稿した[ListUtil.exactlyOne](http://qiita.com/suzuki-hoge/items/fb662ec2ba32747d5a2c#exactlyone)を使って終端操作で済ます

```Java:refactored
Contract found = findEnablingBy(new UserId("001"))
        .collect(ListUtil.exactlyOne(() -> new RuntimeException("not be unique")));
```

### `ListClass` -> `Optional<ElementClass>`
この形も結構あると思う

こちらはもし有効な契約があったら何らかの操作をするパターン
有効な契約が無いかもしれないという仕様に対して書かれたコード

```Java:plain
List<Contract> list = findAll()
        .filter(Contract::isPremium)
        .collect(Collectors.toList());

if (list.size() == 0) {
    Optional<Contract> found = Optional.empty();
} else {
    Optional<Contract> found = Optional.of(list.get(0));
}
```

これも前に投稿した[ListUtil.headOpt](http://qiita.com/suzuki-hoge/items/fb662ec2ba32747d5a2c#headopt)を使って終端操作で済ます

```Java:refactored
Optional<Contract> found = findAll()
        .filter(Contract::isPremium)
        .collect(ListUtil.headOpt());
```

# もっと！もっと書くことをを減らしたい！
重ねて言うけど、別に妙なことが書きたいわけではなくて
言語的に必要な手書き部分をそぎ落としてロジックに集中したいと言うのが意図です

## 生成
### `[]` -> `ListClass`
空リストからの生成は全ての`ElementClass`に手書きしないといけないので、生成してくれるクラスを設けてみた

```Java:Empty
public class Empty {
    public static <ListClass, ElementClass> ListClass of(Function<List<ElementClass>, ListClass> constructor) {
        return constructor.apply(Collections.emptyList());
    }
}
```

```Java:refactored
ContractList empty = Empty.of(ContractList::new);
```

本当は`ContractList.empty()`が良いんだ...
けどJavaって`static`なメソッドは`default`実装を持ったり`abstract`メソッド持ったり出来ないんだよね？
`ContractList`に手書きをせずに`ContractList.empty()`を用意する方法は無いのか...

けど新しい`ListClass`を作るときに書くべき事が一切ない点は○

## Stream
`stream`は型が変わらない場合は第2引数のコンストラクタを無くしてみたかった
あの妙な第2引数が無くなると、「箱がある、中身に何かして、箱に戻す」という風になって
`ListClass(箱)`の`map/filter`は`Stream(箱)`の`map/filter`と雰囲気が同じになるよね

ちょっとどうかなとは思うけど、`ListOf`にコンストラクタを手に入れる方法を教えてあげてみた

```Java:ListOf
public interface ListOf<ListClass, ElementClass> {
    // 一部略

    // このメソッドだけ追加、以下はdefault
    public Function<List<ElementClass>, ListClass> getConstructor();

    public default ListClass map(
            Function<ElementClass, ElementClass> mapper
    ) {
        return map(mapper, getConstructor());
    }

    public default ListClass filter(
            Predicate<ElementClass> predicate
    ) {
        return stream().filter(predicate).collect(ListUtil.construct(getConstructor()));
    }
}
```

```Java:ContractList
public class ContractList implements ListOf<ContractList, Contract> {
    // 色々略

    @Override
    public Function<List<Contract>, ContractList> getConstructor() {
        return ContractList::new;
    }
}
```

### `ListClass` --map--> `ListClass`
`map`した結果型が変わらないパターン
型が変わらないのであれば`map`は自分で`ListClass`のコンストラクタを手に入れる

```Java:refactored
ContractList normals = contracts
        .map(Contract::toNormal);
```

### `ListClass` --filter--> `ListClass`
`filter`は型が変わらないのでコンストラクタを教える必要はない

```Java:refactored
ContractList premiums = contracts
        .filter(Contract::isPremium);
```

### `ListClass` --filter--> `ListClass` --map--> `ListClass`
当然連結も可能

```Java:refactored
ContractList normals = contracts
        .filter(Contract::isPremium)
        .map(Contract::toNormal);
```

これは素より大分すっきりしたと思う
ロジックコードしかない

### `ListClass` --filter--> `ListClass` --map--> `AnotherListClass`
`filter`と、型が異なる`map`の連結

```Java:refactored
UserIdList premiumIds = contracts
        .filter(Contract::isPremium)
        .map(Contract::getUserId, UserIdList::new);
```

`filter`と`map`で引数の数が違うの、微妙...
`map`は`ElementClass`の変換までで、`UserIdList`の生成はまた別であるべきなんだろうか...

# おわりに
隠蔽も度が過ぎると良くないし、書き終わって「あ、`forEach`忘れてた」とかあってまぁ当然全てに対応しているわけでもないので
実運用をもしするならもっと細かいことをチームで考えないと行けないよねー

けど多用する`stream` -> `map/filter` -> `.collect(Collectors.toList())`は相当スッキリしたのでそこは満足した！

Java別に全く好きじゃあ無いんだけど、仕事で使う以上は日中を少しでも快適にしたいじゃんか！と思って考えてみたけど案外楽しかったｗ
またねﾉｼ
