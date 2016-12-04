爆発的にパターンが増えるテストデータはBuilderで作ろう

データベースのモック、作ったAPIのIN/OUTのダミーデータ、外部システムのモック、用途はなんでも良いけどテストデータってしょっちゅう作るじゃん。
でも保守は面倒だし正しく使うのも使わせるのも大変だし、どうにかならんもんかとちょっと考えてみた。

型型したいのでサンプルコードはJava、でも別に何の言語でも良いと思う。

## お題
仮に契約というデータがあり、内容が以下の様な感じだとする。

```Java
{userName=ほげ太郎, plan=NORMAL, items=[Item1, Item2], coupon=}
```

key      | value                          
:--      | :--                            
userName | 必須                           
plan     | NORMAL/PREMIUM                 
items    | 0..*                           
coupon   | NORMAL時はなし、PREMIUM時は必須

このハッシュを作る方法を考えようと言う事。

## 方法
### JSONを使う
おそらくすぐ思いつくやり方。過去にいたチームは`.xml`だったり`.txt`だったりしたこともあるけど、発想は同じ。

```Json:商品複数_割引なし
{
  "userName": "ほげ太郎",
  "plan": "NORMAL",
  "items": [
    "Item1",
    "Item2"
  ]
}
```

```Json:商品複数_割引あり
{
  "userName": "ほげ太郎",
  "plan": "PREMIUM",
  "items": [
    "Item1",
    "Item2"
  ],
  "coupon": "ABC"
}
```

#### メリット
`Json`なら書くのが簡単だし、大抵はパースライブラリがあるので初期コストが低い

#### デメリット
部品化が出来ない

例えば`items`は`空`、`1件`、`同種2件`、`異種2件`といったパターンを用意しておき組み合わせることが出来ない。
新しいパターンを用意するときにまるまるコピーする必要があるので、仕様変更がどんどん辛くなる。

### JavaのMapを使う
Javaの`Map`なら足せるじゃん、という発想

```Java
public class ContractMap {
    private static Map<String, Object> items() {
        Map<String, Object> map = new HashMap<>();
        map.put("items", Arrays.asList("Item1", "Item2"));

        return map;
    }

    public static Map<String, Object> 商品複数_割引あり() {
        Map<String, Object> map = new HashMap<>();
        map.put("userName", "ほげ太郎");
        map.put("plan", Plan.PREMIUM);
        map.put("coupon", "ABC");
        map.put("items", items());

        return map;
    }
    
    public static Map<String, Object> 商品複数_割引なし() {
        Map<String, Object> map = new HashMap<>();
        map.put("userName", "ほげ太郎");
        map.put("plan", Plan.NORMAL);
        map.put("items", items());

        return map;
    }
}
```

```Java
class Main {
    public static void main(String[] args) {
        System.out.println(
                ContractMap.商品複数_割引あり()
        );
    }
}
```

#### メリット
割引有無の2パターンを作るのに複数商品の部分を共通化出来ている

ちゃんとJsonの問題を解決出来ている。
あと地味だけど嬉しい点は`Plan.NORMAL`の様に実コードのEnumが使える点。

#### デメリット
Javaの`Map`って糞ね

まぁそれはJava特有の話であってこの方針の問題とは本質的には関係ないのでスルーで。（Groovyでも使うと良いよ）

まず問題は組み合わせがある場合に適切に設定するのが難しいという点だ。

> `coupon`は`Plan.PREMIUM`の場合は必須、`Plan.NORMAL`の場合は空

こういう仕様上の制約が特に現れていないので、コピペで作り足す時に間違える可能性が高い。


そして一番の問題はパターンが爆発的に増える点だ、これはヤバい。

`Plan`が`NORMAL`/`PREMIUM`の2パターン、商品が`空`/`1件`/`同種2件`/`異種2件`の4パターンで既に8メソッド用意しないといけない。

#### 商品上限の有無
ここで後出し仕様として商品の契約数上限の有無を考えてみる。

```Java
public enum Limit {
    LIMITED, UNLIMITED;
}
```

`Limit`は`Plan`とは特に関連せず、それぞれを適切に設定する必要があるとする。

これが増えるとさっきのデメリットが絶大に響いてくる。

先述の8パターンに加えて、`Limit`が`LIMITED`/`UNLIMITED`の2パターンで16メソッド用意しなければならなくなった！

この方針で正しく全てを用意するのは不可能だ、断然しても良い。
`Limit`はただの二択だけど、`Plan`の内`PREMIUM`を選んだ場合は`coupon`の指定が必要、なんて絶対間違えるに決まってる。

今後支払い方法として`クレジットカード`/`コンビニ決済`なんてのが増えるかも知れない、そしたら32パターン？
`Plan`だって増減があるだろうし、契約以外にも大量のクラスがあるはずで、それら全部なんて絶対ミスが混入するに決まってる。

いやー、それくらいなら大丈夫じゃね？って思うかもしれない。
けど一人で保守するわけじゃあないのでこれらの地雷を情報共有とかコメントとかだけで避けきるのは想像以上に難しいし、
そもそも実際のプロジェクトならもっと巨大な仕様であるだろうしで、この方法は初期コストは低いけど絶対に破綻する。
断言する。というか経験済み。

### Builderを作る
`Map`の例が良くなかった理由はは大きく2つで、「一気に組み立てようとする点」と「部品化を`Map`でしている」点

なにも全パターンを用意しておく必要はないし、最終的に`Map`が欲しいからと言って組み立て途中も`Map`である必要はない。

```Java
public class ContractBuilder {
    private String userName;
    private Plan plan;
    private Limit limit;
    private List<String> items = new ArrayList<>();
    private Optional<String> coupon = Optional.empty();

    public ContractBuilder(String userName) {
        this.userName = userName;
    }

    public static ContractBuilder init(String userName) {
        return new ContractBuilder(userName);
    }

    public ContractBuilder normalPlan() {
        this.plan = Plan.NORMAL;

        return this;
    }

    public ContractBuilder premiumPlan(String coupon) {
        this.plan = Plan.PREMIUM;
        this.coupon = Optional.of(coupon);

        return this;
    }

    public ContractBuilder limited() {
        this.limit = Limit.LIMITED;

        return this;
    }

    public ContractBuilder unlimited() {
        this.limit = Limit.UNLIMITED;

        return this;
    }

    public ContractBuilder item(String item) {
        this.items.add(item);

        return this;
    }
```

この方針だと全てのパターンをこれだけの行数で網羅することが出来る。
一気にフル要素を手に入れる（用意する）のではなく、各要素をだんだんと組み立てて行くイメージで生成する。
で、最後に一度だけ欲しい形に変換して吐き出せば良い。

```Java
    public Contract build() {
        return new Contract(userName, plan, limit, items, coupon);
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();

        map.put("userName", userName);
        map.put("plan", plan);
        map.put("limit", limit);
        map.put("items", items);
        map.put("coupon", coupon.orElse(""));

        return map;
    }
```

保持している値を好きな形に一度だけ変換すれば良いので、`Map`以外でもすぐ吐ける。

`this`を返しているので、こんな感じで連結しながら使う

```Java
Map contract = ContractBuilder
        .init("ほげ太郎")
        .normalPlan()
        .limited()
        .item("Item1")
        .item("Item2")
        .toMap();
```

```Java
Map contract = ContractBuilder
        .init("ほげ太郎")
        .premiumPlan("ABC")
        .unlimited()
        .item("Item1")
        .item("Item2")
        .toMap();
```

#### メリット
先述の通り、これだけで全パターンが網羅できるし例えば支払い方法が2パターン増えても、メソッドを2つ増やすだけで対応が済む。

もう1つのポイントは、例えば`premiumPlan`は`coupon`を引数に取るので「`PREMIUM`だけど`coupon`の設定を忘れる」という事がないし、
「`limited()`の場合のみになんらかの条件を書き足す」という事が容易であること。

#### デメリット
テストデータを用意する側は`Json`や`Map`
