DDDをHaskellで考える EntityとIdentity、そしてモデル図
DDD初心者が拙いHaskellを使って色々考える試みです。

## はじめに
先日[DDDをHaskellで考える 業務ロジックとシステムロジック](http://qiita.com/suzuki-hoge/items/82229b903655ca4b5c9b)という記事を投稿しました。
この試みの個人的なひとまずのゴールとしては「Haskellを軸にレイヤー設計まで考えてみて、何か作りきる」なのですが、
その際に必ず登場するであろう`Entity`に付いて考えてみたいと思います。

ですが正直なところ、今回はあまりHaskellであることを活かせないのではないかと考えています。

また、先日やっとエヴァンス本を購入しましたが、時間が無くて全然読み進められてません。
今後ここで述べた考えを改める可能性もありますが、初学者の学習過程と思ってご容赦ください。

## Haskellについて
手前味噌ですが僕が今回の試みにあたり軸に考えている部分を[先述の投稿](http://qiita.com/suzuki-hoge/items/82229b903655ca4b5c9b)に載せています。
参照透過性と副作用、業務ロジックとビジネスロジック、関数とアクションについてはその記事と同じ意味で用います。

## Entity
1年前、配属がかわり「お前はこれからDDDをやるんだ」と言われたときに、初めて`Entity`と言う単語を聞きました。

当時は何やら全くわかりませんでしたが、「きっと主キーがあって永続化するやつのことだな？」と解釈しました。
この考えは今でも外れていないと思っています。

以下の様な「主キー」と「属性」で表現される様なオブジェクトを以下`Entity`とします。

```Java:Item.java
public class Item {
    private final ItemId id;
    private final ItemName name;
}
```

### Entityのステータス
ところで、永続化する以上は所謂ステータスの様な概念があるはずです。
足してみましょう。

```Java:Item.java
public class Item {
    private final ItemId id;
    private final ItemName name;
    private final ItemStatus status;
}
```

シンプルに解決出来た様に思いますが、この方針をとったことで職場で苦しむことになりました。
この方法は以下の問題にいずれ直面することになります。

+ 全てのステータスにおいて同じ属性を持つとは限らない
+ 特定のステータスの場合のみ行いたい処理を表現しづらい
+ `Item`に関する全てが集まるので巨大になる
+ モデル図（もしくはクラス図）に`Item`というクラスがひとつ現れるだけで得られる情報がほぼない

## Identity
もしかしたらステータスごとに別の`Entity`にしても良かったのでは、と話す様になったころ、たまたま`Identity`という単語を聞きました。
どうやら察するに「`Entity`を一意に特定する値（もしくは値群）」である様です。
（上記`Item`の例で言うと`ItemId`が相当します）

なぜ`Identity`をあえて`Entity`とわけて捉えるのかを考えたところ、必ずしも`Identity`と`Entity`は1:1ではないと言う考えに至りました。

これは丁度疑問に思っていた、`Entity`をステータス毎にわける、と言う考えと一致すると思い、早速試し書きをしてみました。

## お題と試し書き
例によって都合の良いお題を考え、それを実装します。

業者が利用者に商品を貸し出す
（具体的にどの様な商売であるかはこの記事の関心外なので、`Item`と`User`とします）

1. 商品は倉庫にある
 + このとき商品は新品もしくは中古品である
+ 倉庫の商品は引当により引当済みになる
+ 引き当てられた商品は発送により発送済みになる
 + 着荷予定日を持つ
+ 受け取りにより受け取り済みになる
 + 受け取り日時を持つ

また、キャンセルおよび返却により商品は倉庫に戻る

+ ユーザの全ての商品をキャンセルする
+ キャンセルは引当済みか発送済みの状態なら可能
 + 倉庫に戻る際に新品か否かを引き継ぐ
+ 返却は受け取り済みの場合のみ可能
 + 返却の際に中古品とする

実装はHaskellで行います。

### 型を用意
まずは型を用意します。

ただの`String`をラップしただけの型や`Enum`、`import`は省略します。

```Haskell:StockedItem.hs
-- 倉庫の商品
data StockedItem = StockedItem {
    id            :: ItemId,
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    status        :: ItemStatus
} deriving Show
```

```Haskell:ProvisionedItem.hs
-- 引当済みの商品
data ProvisionedItem = ProvisionedItem {
    id            :: ItemId,
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    status        :: ItemStatus
} deriving Show
```

```Haskell:ShippedItem.hs
-- 発送済みの商品
data ShippedItem = ShippedItem {
    id            :: ItemId, 
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    arrival       :: ArrivalScheduledDate, -- 着荷予定日
    status        :: ItemStatus
} deriving Show
```

```Haskell:ReceivedItem.hs
-- 受け取り済みの商品
data ReceivedItem = ReceivedItem {
    id       :: ItemId,
    name     :: ItemName,
    received :: ReceivedDate, -- 受取日
    status   :: ItemStatus
} deriving Show
```

今回は状態毎に違う型としてみました。
また所謂`interface Item`の様なものは無く、これら`XxxItem`は完全に独立した別の型として存在します。

### 受け取り済みまでの振る舞いを用意
次に振る舞いを用意します。

今回は`LifeCycle`という`XxxItem`の遷移についてのみ責任を持つモジュールを実装する形にしてみました。

```Haskell:LifeCycle.hs
provision :: StockedItem -> ProvisionedItem
provision stocked = ProvisionedItem (StockedItem.id stocked) (StockedItem.name stocked) (StockedItem.stockedStatus stocked) Provisioned

ship :: ProvisionedItem -> ArrivalScheduledDate -> ShippedItem
ship provisioned date = ShippedItem (ProvisionedItem.id provisioned) (ProvisionedItem.name provisioned) (ProvisionedItem.stockedStatus provisioned) date Shipped

receive :: ShippedItem -> ReceivedDate -> ReceivedItem
receive shipped date = ReceivedItem (ShippedItem.id shipped) (ShippedItem.name shipped) date Received

-- XxxItem (StockedItem.id stocked) (StockedItem.name stocked) の様な記述は
-- Javaで言うところの new XxxItem(stocked.getId(), stocked.getName()) に相当します
```

当然ですが全て`関数`で実現します。

状態遷移がこの3つの`関数`で表せている感じがします。
また、`ship`には着荷予定日が、`receive`には受取日が必要なことがわかります。

### キャンセルを実現する
キャンセルは引当済み、もしくは発送済みに対して実施できます。
それを実現する方法は軽く考えてもいくつかの方法がある様に思えます。

ここでは`UserId`でDBから商品を複数件を参照してきて、それら全てをキャンセルする処理を考えます。

#### 新しい型を作り、それを複数件得た後にキャンセルを実施する
```Haskell
findCancelable :: UserId -> IO [CancelableItem]

cancel :: CancelableItem -> StockedItem
```

+ :thumbsup:
 + `CancelableItem`が登場する処理はキャンセルに関連する処理だと察しやすい
 + キャンセルに関する仕様変更を`CancelableItem`関連に局所化出来そう
+ :thumbsdown:
 + 型もリポジトリもものすごい数になりそう
 + キャンセル可能とは何か、がリポジトリに隠れてしまう（後述）

#### 引当済みリストの参照と発送済みリストの参照を別に行い、両方の全てをキャンセルする
```Haskell
findProvisionedItems :: UserId -> IO [ProvisionedItem]

findShippedItems :: UserId -> IO [ShippedItem]

cancelProvisionedItem :: ShippedItem -> ProvisionedItem

cancelShippedItem :: ShippedItem -> StockedItem
```

+ :thumbsup:
 + キャンセルを実現する際に増える型やアクションがない
 + 更に別の要求を実現する際も、特に新たに何かを用意する必要が無い
+ :thumbsdown:
 + リポジトリにキャンセルという単語が現れないので影響範囲を限定できない感じがする
 + 他にもキャンセル可能なステータスが出来た場合に書き足すことが多そう
 + `provisioned`と`shipped`をたらい回すいたる箇所で「その2つがキャンセル可能である」と脳内補完しなければならない

#### 上記の方法をタプルを使い実現する
```Haskell
findCancelable :: UserId -> IO ([ProvisionedItem], [ShippedItem])

cancelProvisionedItem :: ShippedItem -> ProvisionedItem

cancelShippedItem :: ShippedItem -> StockedItem
```

+ :thumbsup:
 + タプルにすれば`provisioned`と`shipped`をある程度はまとめておける
 + タプルであれば色々な複数を扱う概念を全てタプルで済ませられるので、新たな型を用意するよりは楽そう
+ :thumbsdown:
 + キャンセル可能という概念が存在するのにただタプルで表現するのはDDD的ではないのではないか
 + Haskellは3要素以上のタプルを扱うのが少し面倒な気がする

#### ではどうするか
上記いずれにも長短があるが、感覚としては最初に述べた`CancelableItem`を採用するべきだと感じている。
もともとが複数ステータスを1つの型で表現したら苦しんだという課題のはずなので、今回は極端なまでに型を分けてみたいと思う。
（結局のところこの試みは初学者の探求なので、迷ったら極端に振り切ってみようと思う）

しかし`findCancelable :: UserId -> IO [CancelableItem]`の様な型定義だと、内部の実装は
`where status == Provisioned or status == Shipped`みたいにハードコードになってしまうだろう。

リポジトリについては後々じっくり考えたいが、仕様を極力型で表現しようと思い、今回はあまり深く考えずに`CancelableCond`と言う型を用意してみることにする。

```Haskell:CancelableCond.hs
data CancelableCond = CancelableCond { status :: [ItemStatus] } deriving Show

cancelableCond = CancelableCond [Provisioned, Shipped]

-- コンストラクタを非公開関数にしておけば cancelableCond が唯一の CancelableCond の値に出来ると思う
```

これを用いてリポジトリの参照アクションを以下の様に実装してみるとする。

```Haskell
findCancelable :: UserId -> CancelableCond -> IO [CancelableItem]
```

これで型とアクション名からキャンセルに関するアクションであることも、具体的にキャンセル可能とは何かも知ることが出来そう。

そしてこの方針をとるのであれば、今後型がとても増えることに覚悟を決めて`CancelableItem`を用意しなければならない。

```Haskell
data CancelableItem = CancelableItem {
    id            :: ItemId,
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    status        :: ItemStatus
} deriving Show
```

この2つを用意すれば、あとは実装あるのみだ。
`LifeCycle`にキャンセルと、勢いで返却も実装してしまおう。

```Haskell:LifeCycle.hs
cancel :: CancelableItem -> StockedItem
cancel cancelable = StockedItem (CancelableItem.id cancelable) (CancelableItem.name cancelable) (CancelableItem.stockedStatus cancelable) Stocked

returnBack :: ReceivedItem -> StockedItem
returnBack received = StockedItem (ReceivedItem.id received) (ReceivedItem.name received) Used Stocked
```

目立たないけど、返却する際は`Used`が固定で埋め込まれているのがポイントです。

## やってみて
結局今回は`Identity`は`Item`を特定するが、特定した結果どのステータスの`Entity`を得るかは文脈に応じてリポジトリを使い分けることで決める、と言う方針を取った。

他のアクションの定義イメージ

```Haskell
findProvisioned :: UserId -> ProvisionedCond -> IO [ProvisionedItem]

findCancelable :: UserId -> CancelableCond -> IO [CancelableItem]

findReceived :: UserId -> ReceivedCond -> IO [ReceivedItem]
```

キャンセルと言う仕様が`Cancel`と言う単語で現れる事で、仕様の表現度と改修範囲の局所化が出来そうだ。
型やアクションが多いくなる事の大変さはもう少し規模を大きくしないとわからないと思うので、今回はここまで。

### モデル図
`Entity`を分けた場合のもう一つの利点として、モデル図が自然と多くの情報を表現出来る様になると言う点があると感じた。

クラス図ではなくて、状態遷移図を書いてみた。
型を四角で、振る舞いを矢印で表現出来ているし、必要なパラメータが必要なタイミングで渡される様が見て取れる。
![LifeCycle.png](https://qiita-image-store.s3.amazonaws.com/0/113398/12f8838b-faff-b09a-bb59-4d3a968fde55.png)

巨大`Entity`の表現をクラス図で済ませてしまうと、得られる情報が少なくなってしまう。
例えば`Optional`の項目が埋まるタイミングや、各振る舞いが実行出来るのはどの状態の`Entity`なのか、と言った肝心な部分がわからない。
![Item.png](https://qiita-image-store.s3.amazonaws.com/0/113398/15667231-83ab-b325-9a39-a06aa3079620.png)


### ステータス毎にクラスをわけなかった場合の実装
せっかくなので、ステータスを分けなかった場合の実装を`Java`で考えてみることにする。

```Java:Item.java
public class Item {
    private final ItemId itemId;
    private final ItemName itemName;
    private final ItemStatus itemStatus;
    private final Optional<StockStatus> stockStatus;
    private final Optional<ArrivalScheduledDate> arrivalScheduledDate;
    private final Optional<ReceivedDate> receivedDate;

    public StockStatus getStockStatus() {
        return stockStatus.orElseThrow(
                () -> new RuntimeException("no StockStatus present")
        );
    }

    public ArrivalScheduledDate getArrivalScheduledDate() {
        return arrivalScheduledDate.orElseThrow(
                () -> new RuntimeException("no ArrivalScheduledDate present")
        );
    }

    public ReceivedDate getReceivedDate() {
        return receivedDate.orElseThrow(
                () -> new RuntimeException("no ReceivedDate present")
        );
    }

    public Item returnBack() {
        assert itemStatus == ItemStatus.Received;

        return new Item(
                itemId,
                itemName,
                itemStatus,
                Optional.of(StockStatus.Used),
                Optional.<ArrivalScheduledDate>empty(),
                Optional.<ReceivedDate>empty()
        );
    }
}
```

一部しか書いてませんが、こんな感じになるのではないかと思います。

`ship`や`returnBack`を命じる前に自身のステータスをチェックしたり、`Optional`の中身を無理矢理取り出す`getter`が必要になります。
これの一番の問題は、それらが実行例外になることです。

せっかく静的言語でやっているのに、肝心のロジック部分が実行例外ではなんか心許ないというかもったいないというか、そんな感じがします。

### Entityを分けた場合にステータスを持つべきか
ステータスごとに`Entity`を分けた場合、`ItemStatus`をデータ構造的に保持するべきか、少し迷いました。

特に強い理由はありませんが、今回は持たせています。
もう少し大きなコードを書いてみてまた考えたいと思います。

## おわりに
今回は以上です。
あまりHaskellである事を活かせた感じはしませんが、手書きしてみたコードと出来たモデル図から経験値は得られたのではないかと思います。

もっと軽く書き上がる感じにしたいので、次は失敗の表現に付いて短くまとめてみる予定です。
