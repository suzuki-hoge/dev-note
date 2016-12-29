爆発的にパターンが増えるテストデータはBuilderで作ろう

データベースのモック、作ったAPIのIN/OUTのダミーデータ、外部システムのモック、用途はなんでも良いけどテストデータってしょっちゅう作るじゃん。
でも保守は面倒だし正しく使うのも使わせるのも大変だし、どうにかならんもんかとちょっと考えてみた。

型型したいのでサンプルコードはJava、でも別に何の言語でも良いと思う。

## お題
仮に契約というデータがあり、内容が以下の様な感じだとする。

```Java
{userName=ほげ太郎, plan=NORMAL, limit=UNLIMITED, items=[Item1, Item2], coupon=}
```

key      | value                          
:--      | :--                            
userName | 必須                           
plan     | NORMAL/PREMIUM                 
limit    | UNLIMITED/LIMITED
items    | 0..*                           
coupon   | NORMAL時はなし、PREMIUM時は必須

このハッシュを作る方法を考えようと言う事。

## 方法
過去に所属したチームでは`.xml`や`.json`や`.txt`で全パターン作って用意しておいたり、以下の様なJavaで書かれたテストデータもあった。

```Java
public static Map<String, Object> 商品複数_割引なし() {
    Map<String, Object> map = new HashMap<>();
    map.put("userName", "ほげ太郎");
    map.put("plan", "NORMAL");
    map.put("limit", "UNLIMITED");
    map.put("items", Arrays.asList("Item1", "Item2"));

    return map;
}
```

それらに共通する問題は「全パターン用意すると膨大になる点」と「`couponはNORMAL時はなし、PREMIUM時は必須`の様な仕様が漏れ易い点」だ。

テキトーに数えてみても、例えば`items`は`0件`、`1件`、`2件`の場合を用意するとして
`plan2種 x limit2種 x items3種 = 12件`の用意が必要になってしまう。

数年の仕様変更を経てそれに`plan2種`と`支払い方法3種`が増えたりして、`LIMITED`の場合は`コンビニ決済`は不可能、なんてなってきたら絶対に破綻する、断言する。

### Builderを作る
Builderを使って部分部分を組み立てる方法だけ用意し、使う側が欲しい様に組み立てられる様にしてみる。
また、最終的に`Map`が欲しいからと言って内部での中間生成状態まで`Map`である必要もない。

```Java
public class ContractBuilder {
    private String userName;
    private Plan plan;
    private Limit limit;
    private List<String> items = new ArrayList<>();
    private Optional<String> coupon = Optional.empty();

    public ContractBuilder userName(String userName) {
        this.userName = userName;

        return this;
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
}
```

この方針だと全てのパターンをこれだけの行数で網羅することが出来る。
一気にフル要素を手に入れるのではなく、各要素をだんだんと組み立てて行くイメージで生成する。
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

保持している値を好きな形に一度だけ変換すれば良いので、`Map`以外にもすぐ吐ける。

`this`を返しているので、こんな感じで連結しながら使う

```Java
Map contract = new ContractBuilder()
        .userName("ほげ太郎")
        .normalPlan()
        .limited()
        .item("Item1")
        .item("Item2")
        .toMap();
```

```Java
Map contract = new ContractBuilder()
        .userName("ほげ太郎")
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
利用する側が正しく組み立てる必要があるので、不正な状態を生成してしまう可能性がある。

```Java
Map contract = new ContractBuilder()
        .toMap();
```

```Java
Map contract = new ContractBuilder()
        .userName("ほげ太郎")
        .normalPlan()
        .normalPlan()
        .normalPlan()
        .toMap();
```

これはどこかでぬるぽを起こすので避けたい。

また、エディタの補完対象を見ても今一使い方がわからない点も問題だ。
例えば「`normalPlan()`と`premiumPlan()`が排他なのか」、「`plan`と`limit`は排他なのか両方設定するべきなのか」、「順番やメソッド間の依存はあるのか」、「何を満たせば`toMap`を実行して大丈夫なのか」と言ったことが察せない。

<img width="754" alt="builder.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/5cba8e23-1ee0-3c16-b128-fe896e5e8a5d.png">

### 1要素を選択する毎に異なるクラスを返す
上記の問題を解決するには、`return this;`の所をそれぞれ違う型にする方法がある。

```Java
public class ContractStrictBuilder {
    private String userName;
    private Plan plan;
    private Limit limit;
    private List<String> items = new ArrayList<>();
    private Optional<String> coupon = Optional.empty();

    public _Plan userName(String _userName) {
        userName = _userName;
        return new _Plan();
    }

    public class _Plan {
        public _Limit normalPlan() {
            plan = Plan.NORMAL;

            return new _Limit();
        }

        public _Limit premiumPlan(String _coupon) {
            plan = Plan.PREMIUM;
            coupon = Optional.of(_coupon);

            return new _Limit();
        }
    }

    public class _Limit {
        public _Item limited() {
            limit = Limit.LIMITED;

            return new _Item();
        }

        public _Item unlimited() {
            limit = Limit.UNLIMITED;

            return new _Item();
        }
    }

    public class _Item {
        public _Item item(String item) {
            items.add(item);

            return new _Item();
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
    }
}
```

この様に2択を迫る異なるクラスを次々と返す事で利用者は正しく組み立てることが出来る。

#### メリット
下のキャプチャが示す通り、「必ずこの2つから選ぶ」「ここまで来たら`toMap`を実行して良い」という事がエディタに教えてもらえるのが最大のメリット。

まず`userName`を必ず設定する
<img width="754" alt="strict_userName.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/f1cad372-b9e4-acfd-9d99-98d26d85aa20.png">

次は`plan`を必ず設定する
この際に`PREMIUM`の場合は必ず`coupon`を設定する
<img width="754" alt="strict_plan.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/be05d336-5b40-6706-83e7-540a5c31f1c4.png">

次は`limit`を必ず選択する
<img width="754" alt="strict_limit.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/9f0c02ea-0f52-f4b8-1f01-e007baaf9f5a.png">

次は`items`の設定だが、`toMap`も実行出来るので`items`は任意項目である事がわかる
<img width="754" alt="strict_items.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/001e45e4-0b61-7528-c03b-12e102483b32.png">

気が済んだら`toMap`を呼ぶ
<img width="754" alt="strict_toMap.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/e9a50ea3-a674-6728-4e74-a6bf3ada26ec.png">

#### デメリット
当然だが実装コストはかかる。

### まとめ
2つのBuilderを考えてみたが、どちらが優れているかという話ではなくて適材適所だと思う。

ただ後者の例はエディタで次々と「どっち？」「どっち？」って聞かれるのでなんか楽しくて好きw
使うだけなら圧倒的に後者が使い易いしね。

そんな訳でぜひ良いパターン管理を
おつﾉｼ
