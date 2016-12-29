DDDをHaskellで考える 失敗を表現する
DDD初心者が拙いHaskellを使って色々考える試みです。

## はじめに
先日[DDDをHaskellで考える EntityとIdentity、そしてモデル図](http://qiita.com/suzuki-hoge/items/7ac33356526764feeb20)という記事を投稿しました。
その中で「実行例外」と言うのが出てきたので、今回は失敗に付いて考えてみたいと思います。

## Haskellについて
手前味噌ですが僕が今回の試みにあたり軸に考えている部分を[最初の投稿](http://qiita.com/suzuki-hoge/items/82229b903655ca4b5c9b)に載せています。
参照透過性と副作用、業務ロジックとビジネスロジック、関数とアクションについてはその記事と同じ意味で用います。

## 失敗について
Haskellで失敗を表現する方法はいくつかあります。

+ `Maybe`を使う
+ `Either`を使う
+ 例外を使う

他、まま見られる「リターンコードが1」とか「`null`を返す」とかは論外なので無視します。

これらの方法で表現される失敗の違いについて考えてみたいと思います。

### 業務ロジック都合で発生する失敗
システムは正常に動いて、意図するチェックに引っかかった様な場合は「業務ロジック都合で発生した」と捉えます。

+ 未成年なので契約出来ない
+ 複数項目から何らかの値を生成しようと思ったけど組み合わせが悪かった
+ 任意項目の参照を行ったら無かった

例えば上記の様な場合は`Maybe`や`Either`を用いて「失敗するかもしれない」事を型で表現します。

何かの情報に基づいて"あるかもしれない"契約出来ない理由を調べるのであれば、`Maybe`を用いて関数を作ります。

```Haskell
checkContractable :: Foo -> Bar -> Maybe InvalidReason
```

"成功したら"結果を、"失敗したら"理由が必要であれば`Either`です。

```Haskell
construct :: Foo -> Bar -> Either FailureReason Baz
```

"あるかないか"どちらもあり得る参照アクションは、やはり`Maybe`を使います。

```Haskell
findItem :: UserId -> ItemName -> IO (Maybe Item)
```

#### 例外は使わない
業務ロジック都合で発生する失敗は例外を使って表現するのは不適切だと考えています。

理由はいくつかありますがひとつ挙げるなら、業務ロジックとは「場合により失敗することもある」と言う事を含めて業務ロジックなので、それを型に現れる様にするのが適切だと考えるからです。

### システム都合で発生する失敗
業務ロジック上想定していない失敗についても考えてみます。

+ DBに接続出来ない
+ ユーザに対する商品が見つからない
 + ユーザは必ず商品を1つは購入しているとする場合
+ 外部Httpリクエストのタイムアウト

例えば上記の失敗は「業務ロジックとして想定しているわけではない」ため、例外で表現します。

DBに接続出来ないかも知れないことを型で現したりはしません。

```Haskell
findUser :: UserId -> IO (Either ConnectionException User) -- とはしない

findUser :: UserId -> IO User
```

DB構造的に見つかるはずのテーブル結合で状態不整合が発生することを型で呼び元に現したりはしません。

```Haskell
findItem :: UserId -> IO (Either InconsistentException [Item]) -- とはしない

findItem :: UserId -> IO [Item]
```

タイムアウトを`Either Left`で返したりはしません。

```Haskell
callApi = do
    ...
    if ...
        then do
            ...
            return $ Right response
        else do
            ...
            return $ Left timeoutException
```

#### MaybeやEitherは使わない
意図していない失敗は言葉通り「例外」で表現するのが適切だと考えます。

プロダクトを作るには当然例外処理も設計も必要ですが、例えば業務フロー図には業務上想定したYes/Noの分岐しか現れないと思います。
それと同じで想定していない失敗をいちいち型で明記するのは不適切だと感じるし、冗長だと思っています。

## 他細かな気になっていること
失敗についての現状の理解は以上です。
あとは補足蛇足の様なものになります。

### バリデーションはどっちか
例えばAPIを作っていて、飛んできたパラメータの桁やフォーマットが正しく無い場合、それは例外でしょうか？

曖昧な表現ですが、受け取ってチェックする以上想定しているとも思えるし、外の世界との窓口はシステマチックな話とも思えます。

フォーム部品についてもいずれ試し書きをしてみたいと思っていますが、今は以下の様に`Either`を使った`関数`にしたいと思っています。
理由はまた改めて述べる機会を作りたいと思います。

```Haskell
UserIdForm :: String -> Either Error UserId
```

### RepositoryとMapper
今回何例かあったDBアクセスを行うアクションですが、厳密には例えば`Spring Framework`では`RepositoryImpl`と`Mapper`で実現されたりします。

例えば主キーでの参照ですが、その参照結果が「ないかも」「ないと状態不整合だ」と言うのは呼ばれた時の文脈次第で変わります。
ですが`Mapper`はただテーブルとそのプログラミング言語上のデータ構造との変換を行うだけで、文脈を存在させるべきではありません。
参照系の場合は`Mapper`は`Maybe`かリストでただ命じられた参照を行い、それが「ないはずはない」とかは`Mapper`より上の層で行うべきです。

#### なくてもよい/ないはずがない
それらの制御は`RepositoryImpl`で済ませます。
理由は`Repository`の型で「あるはず」「ないかも」を表現したいからです。

例えば商品を購入したユーザに対する処理で、ユーザIDから商品を参照する場合。これは「あるはず」なので下記の様になります。

```Haskell:RepositoryImpl.hs
findPurchasedItem :: UserId -> IO Item
findPurchasedItem userId = do
    res <- findByUserId userId
    case res of
        (Just x) -> return x
        Nothing  -> throwIO $ userError "not found"
```

対してユーザの状態は気にしていない処理で、購入可能な商品が「あれば」表示する様な場合は下記の様になります。

```Hakell:RepositoryImpl.hs
findPurchasableItem :: UserId -> IO (Maybe Item)
findPurchasableItem userId = do
    findByUserId userId
```

どちらも同じ`Mapper`の`findByUserId`を利用していて、それの戻りは`Maybe`です。

この様に`Mapper`はアクション名も無機質であるはずないはずなんて知らない、という程度の処理であり、
それを使う`RepositoryImpl`があるはずないはずを適切に判断し、型に現します。
この際に`RepositoryImpl`には業務ロジックを表現できる名前に出来ることがベストかと思います。

### NullObjectパターン
`Java`等で見られる作りです、いきなりですが、個人的には嫌いです。

`interface`で`Item`を用意し、`ExistingItem`と`NonexistentItem`がそれを実装する様な作りです。
砕いて言えばただのストラテジパタンだと思っています。

実務で使っていましたが、`nonexistent`の場合の振る舞いって案外無くて大抵は「用意させられるだけ」の様な感じでした。
大抵の場合は`existing`の方だけが現れるし、下手に使うとキャスト例外等を起こす可能性をはらんでいるので、個人的にはメリットを感じていません。

最近は`Optional`を使っています、`Haskell`の`Maybe`に相当します。

上記の通り面倒な割にメリットを感じないのも理由ですが、当然最大の理由は型からわかる情報が少ないからです。

```Java
public Item findPurchasableItem(UserId userId) {
```

これが「必ずひとつ返す」のか「ないかも」を表現しているのかがわからないからです。

## おわりに
今回は以上です。

今回の記事は`Haskell`である事を活かせた感じがしています。
`Form`や`Repository`についてもおいおい踏み込んでいきたいと思います。
