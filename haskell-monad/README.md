HaskellのFunctorとApplicativeFunctorとMonad

Haskellの理解度がペラッペラなので勉強し直した、そんなまとめ

モナドとか軽々に言うと怖いお兄さんが嬉々としてマサカリ投げに来るらしい
あーもなどもなど

## きっかけと目的
使ってみたいモジュールがあるのと、ちゃんと理解したいコードがあるから

なので目的はとりあえず読める様になり、あり物を使える様になること

### 知りたかったことと勉強前理解度
キーワード         | 理解                                    
:--                | :--                                     
instance           | 自前でShowを書くときに使うやつ          
Functor            | はて                                    
ApplicativeFunctor | Functorよりすごいらしい、恐い           
Monad              | ApplicativeFunctorよりすごいらしい、怖い
pure               | よくみる                                
fmap               | たまにみる                              
<$>と<*>           | よくみる                                
do                 | 超よくみる、全然わからん                

### やってないこと
+ 自作はまだしないので、則について細かく理解するのはまた今度
 + Functor則
 + ApplicativeFunctor則
 + Monad則
+ 直近で使いたいMaybe, Either以外のモナドはまた今度
 + IO
 + List
 + Writer
 + Reader
 + State

### 教材
すごいH本

## さっそく、の前に
`Maybe`が一番わかりやすいと思い、H本の展開に則って自分で作ってみることにした

```Haskell
data Opt a = None | Some a
```

なんとなくScala風
ずっとこいつを使います

あと、今後はOptとかMaybeとかIOとかの型コンストラクタを文脈と言います
`Opt Int`は`Optの文脈に入ったInt値`、みたいな

## derivingとinstance
まず間違いなく自前の型をFunctorとかにするにはinstanceキーワードが出てくるはず
Showで練習しておかねば

### deriving
よく使う感じ
Haskellにお任せする

```Haskell
data Opt a = None | Some a deriving Show
```

### instance
自分で挙動を変えるなら、導出(deriving)しないでinstanceキーワードで自分で定義する

```Haskell
instance Show (Opt a) where
    show None = "None"
    show (Some a) = "Some: " ++ show a
```

あれ、これだと`show a`が出来る保証がないな...どっかに`Show a =>`って書かないといけないのかな？

```Haskell
instance (Show a) => Show (Opt a) where
    show None = "None"
    show (Some a) = "Some: " ++ show a
```

こんな感じか

## Functor
関数を、文脈のある値に適用できる

### 実装
こんな実装らしい

```Haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

中身の値を直接変換する関数と、Functorの値で、新たなFunctorの値にする、って感じっぽい

Optで考えると、中身があるなら適用して、ないならないまま、って感じかな？
さっそくMaybeの実装を写経する

```Haskell
instance Functor Opt where
    fmap f None = None
    fmap f (Some a) = Some $ f a
```

`Functor f`と`Functor Opt`が対応しているので、さっきのfmapを読み替えてみる

```Haskell
fmap :: (a -> b) -> Opt a -> Opt b
```

具体化すると簡単に読めるな
使ってみよう

```Haskell
fmap (+2) None
-- None

fmap (+2) (Some 5)
-- Some: 7
```

中身があるかどうか気にしないで扱えちゃうってことだね、便利

### 使う
もう少しいろいろやってみよう
適当な2つの関数を作っておいて、いろいろ合わせ技をしてみる

```Haskell
optHalf :: Int -> Opt Int
optHalf x = case even x of
    True -> Some $ half x
    _    -> None

half :: Int -> Int
half = (`div` 2)
```

```Haskell
let some = optHalf 40
some
-- Some: 20

fmap optHalf some
-- Some: Some: 10
-- 間違えた、これは (Int -> Opt Int) を Opt Int の中身に適用しちゃうのでネストしちゃう

fmap half some
-- Some: 10

-- もう一度半分にしたい場合は？
fmap half (fmap half some)
-- Some: 5

-- 演算子化して間に置いてみる
half `fmap` some
-- Some: 10

-- ところで <$> ってのが fmap と同じらしい
half <$> some
-- Some: 10

-- 中身に2度適用するなら、先に関数合成して置いても同じ なるほど
fmap (half . half) some
-- Some: 5
```

なんとなく好きに書ける様になったぞ？

### まとめ
```Haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

+ 1引数関数を中身に適用する
+ `<$>`はfmapと同じ
+ 関数もファンクターに含まれる場合、ファンクター値を写すことは出来ない

### 疑問
ところで、`Some 5 + Some 3`とかは出来ないのかな？
あと`half`は奇数でも割っちゃうので、`optHalf`を繰り返したい

## ApplicativeFunctor
文脈のある関数を、文脈のある値に適用できる

### Functorの出来ないこと
2引数関数だとどうなるか

```
ghci> :t fmap (+) (Just 3)
fmap (+) (Just 3) :: Num a => Maybe (a -> a)
```

関数がMaybeに入ってしまった

> + 関数もファンクターに含まれる場合、ファンクター値を写すことは出来ない

fmapではこれ以上どうにもならないっぽい

### 実装
Applicativeの実装はこんな感じらしい

```Haskell
class (Functor f) => Applicative f where
    pure :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b
```

+ ApplicativeならFunctorであるという制約がついている
+ pureはデフォルトの文脈に突っ込む最低限の処理らしい、はて？
+ `(<*>)`はfmapと似てるけど、最初の関数も文脈に含まれている

OptもApplicativeFunctorにしてみよう

```Haskell
instance Applicative Opt where
    pure = Some
    None <*> _ = None
    (Some f) <*> something = fmap f something
```

`pure = Some`か、なるほど、Optにするってことか
次の行は、`f (a -> b)`がNoneだった場合は計算しようが無いのでNoneになると書いてある
最後の行は`f (a -> b)`がなんかだった場合、`(a -> b)`の部分をfmapすると書いてある

最後の行がポイントっぽい

まるで`f (a -> b)`からfを外しているみたい
それにsomethingにfmapしたらやっぱり結果はOptになるのと、Functorであることが制約で保証されてるからfmapが使えるってのがキモらしい

### 使う
まず、fmapで2引数関数を取るのと、1引数関数を文脈に入れるのは同じ

```
ghci> :t fmap (+) (Some 3)
fmap (+) (Some 3) :: Num a => Opt (a -> a)

ghci> :t Some (+3)
Some (+3) :: Num a => Opt (a -> a)
```

文脈に入れるのはpureも同じ（実際`pure = Some`だし）

```
ghci> :t pure (+3)
pure (+3) :: (Num a, Applicative f) => f (a -> a)
```

けどpureには「Optの文脈だよ」って言ってないから、まだ抽象的な持ち方をしているって感じかな？

この3種どれでも、`<*>`で同じ文脈の値に適用できるんだったね

```Haskell
fmap (+) (Some 3) <*> (Some 5)
-- Some: 8

Some (+3) <*> (Some 5)
-- Some: 8

pure (+3) <*> (Some 5)
-- Some: 8

-- おぉ, Opt Int に Opt (Int -> Int) が適用できてる

-- もちろんどちらかが None ならお察しの通り

None <*> (Some 5)
-- None

pure (+3) <*> None
-- None
```

もう少し触ってみよう

fmapは`<$>`とも書けるから

```Haskell

(+) <$> (Some 3) <*> (Some 5)
-- Some: 8
```

おぉ！よく見るやつだ！最初だけ`<$>`でそれ以降が`<*>`なやつ！

3引数も...試してみよう！

```
let foo x y z = x + y + z

foo 1 2 3
-- 6

foo <$> (Some 1) <*> (Some 2) <*> (Some 3)
-- Some: 6

foo <$> (Some 1) <*> None <*> (Some 3)
-- None
```

おぉぉぉぉ！楽しい！

> ところで、`Some 5 + Some 3`とかは出来ないのかな？

できたね！
これすごいのはfooはあくまで`Int -> Int -> Int -> Int`なのに、Optの文脈で使えちゃってる点
foo自体はそのまま使っていて、違う文脈でも使えちゃうのがすごいところ

だから例えばEitherでもおｋ

```Haskell
foo <$> (Right 1) <*> (Right 2) <*> (Right 3)
-- Right 6

foo <$> (Right 1) <*> (Left "even not allowd") <*> (Right 3)
-- Left "even not allowd"
```

カッチョイイZE！

### まとめ
```Haskell
class (Functor f) => Applicative f where
    pure :: a -> f a

    (<*>) :: f (a -> b) -> f a -> f b
```

+ 文脈に入った関数を文脈の値に適用する
+ 引数はいくつでも良い
+ `<*>`を使って適用する

以下の結果は全部同じ

```Haskell
fmap (+) (Some 1) <*> (Some 2)

(+) <$> (Some 1) <*> (Some 2)

pure (+) <*> (Some 1) <*> (Some 2)
```

### 疑問
この時点で結構凄いと思う
Monadってのは何が出来るん？

## Monad
文脈のある値を、文脈を付けて返す関数に適用する

文脈を保ったまま、関数に渡したい
って感じ？

### 実装
実装を見よう

```Haskell
class Monad m where
    return :: a -> m a

    (>>=) :: m a -> (a -> m b) -> m b

    (>>) :: m a -> m b -> m b
    x >> y = x >>= \_ -> y

    fail :: String -> m a
    fail msg = error msg
```

+ returnはpureみたいなもの
+ `(>>=)`は良く聞くbindと言うやつ
+ `(>>)`はデフォルト実装がある、普通は上書きしないらしい
+ `fail`もデフォルト実装がある、普通は自前で呼ばないでHaskellが呼ぶらしい

returnは文脈につっこむだけなんだね！（正直なところ、IO専用のイメージだった）
大抵最後は文脈に突っ込んで終わるから、最後の行がreturnって場合が多いのかな

では最後にOptにMonadになってもらおう

```Haskell
instance Monad Opt where
    return = Some
    None >>= f = None
    Some x >>= f = f x
    fail _ = None
```

returnはpureと同じで、Optの世界に値を放り込むんだね
`None >>= f`がNoneなのはイメージしやすい
`Some x >>= f = f x`って、まるでxからSomeを引っぺがしている様だね、けど`(a -> m b)`だから、`f x`はまたSomeの文脈に戻る
これが文脈を引っぺがすみたいだけど、文脈からそとに漏れないってことなのかな
failはただのNoneになったみたい、失敗系モナドだから、例外よりその方が良さげ

### 使う
まずreturnから
returnは別にIO専用ではない！

```Haskell
return 5 :: Opt Int
-- Some: 5

return 5 :: Either String Int
-- Right 5
```

ちゃんとなんかの文脈に入って返ってきた

次は`>>=`ね、いままで何となくで書いてなんか怒られてたこれ、今見ると全然だめだね

```Haskell
return 5 >>= (+2)
```

`>>=`の先はまた同じ文脈にいれないといけないから
（ちなみに、`Some 5`に2を足したいなら最初にやった`(+2) <$> Some 5`だからね！すらすら書けるぜー）

`Int -> Opt Int`の関数を適当に用意

```Haskell
let optInc x = Some $ x + 1

optInc 5
-- Some: 6
```

で、使う

```Haskell
Some 5 >>= optInc 
-- Some: 6

return 5 >>= optInc 
-- Some: 6
```

うん、出来ているね
`return = Some`だから、pureの時の例と同じで、どっちも結果は同じ

ところで、Functorの時に出てきたoptHalfが`Int -> Opt Int`だったなそういえば！

再掲

```Haskell
optHalf :: Int -> Opt Int
optHalf x = case even x of
    True -> Some $ half x
    _    -> None
```

```Haskell
return 6 >>= optHalf 
-- Some: 3
```

お、ピッタリだ
んで、得た値がOptということは...

```Haskell
return 6 >>= optHalf >>= optHalf 
-- None
```

> あと`half`は奇数でも割っちゃうので、`optHalf`を繰り返したい

出来たね！
`Int -> Opt Int`なのに結果をどんどん次に連結している！（いちいちOptを引っぺがしている感じはないけど）

これもApplicativeFunctorと同じで、`>>=`は文脈次第なので、EitherはまたOptとは違った感じになる
けど、ApplicativeFunctorで使った`(+)`とは違い、最後に文脈に入れないといけないので関数は都度用意しないといけないのかな？

```Haskell
up :: Int -> Either String Int
up x
    | x < 2     = Right $ x + 1
    | otherwise = Left "too big"

down :: Int -> Either String Int
down x
    | 0 < x     = Right $ x - 1
    | otherwise = Left "too small"
```

ある境界を越えると失敗するって感じ

使ってみよう

```Haskell
return 0 >>= inc
-- Right 1

return 0 >>= inc >>= inc
-- Right 2

return 0 >>= inc >>= inc >>= inc
-- Left "too big"

return 0 >>= inc >>= dec >>= dec
-- Left "too small"

return 0 >>= inc >>= dec >>= dec >>= inc >>= inc
-- Left "too small"
```

どのタイミングで失敗したかって気にしないでいくらでも連結できてる！

あと書いてて気付いたんだけど、returnが適切な文脈に突っ込んでくれるってことは、incとdecを何もEither専用にしないことが出来る気がする！

```Haskell
inc :: (Monad m) => Int -> m Int
inc x
    | x < 2     = return $ x + 1
    | otherwise = fail "too big"

dec :: (Monad m) => Int -> m Int
dec x
    | 0 < x     = return $ x - 1
    | otherwise = fail "too small"
```

こうかー！

```Haskell
Some 1 >>= inc
-- Some: 2

Some 1 >>= inc >>= inc
-- None

Some 1 >>= inc >>= inc >>= dec
-- None
```

Someでも使えた！
returnはSomeで、failはNoneって実装だからね！

けどEitherのfailはerrorだった、Leftじゃあないのかー残念

```Haskell
Right 1 >>= inc >>= inc
-- *** Exception: too big
```

ところで、returnに慣れてきたので、以下は正しいけど

```Haskell
Some 5 >>= (\x -> return $ x + 1)
-- Some: 6
```

これはおかしいってのが、今ならわかる

```Haskell
Some 5 >>= (\x -> return None)
-- Some: None
```

returnはいつも使っているreturn文ではないから、`戻す`ってことじゃあない！
Optの文脈においては`return = Some`だから、`return None`ってしたらネストしちゃうね！

### まとめ
```Haskell
class Monad m where
    return :: a -> m a

    (>>=) :: m a -> (a -> m b) -> m b

    -- (>>) と fail は略
```

+ 文脈に入った値を、文脈を付ける関数に適用する
+ `>>=`を使って適用する
+ returnは戻すって意味ではない

### 疑問
doが`>>=`の糖衣構文ってのは聞いたことある
ここまで来たらdoも知りたい！

## do記法
複数のモナド値を糊付けする

### 使う
`>>=`での結合がネストしている場合があるとする

```Haskell
Some 3 >>= (\x -> Some "!" >>= (\y -> Some (show x ++ "!")))
-- Some: "3!"
```

これはもう当然って思えるけど、どこかがNoneになったら最終的にNoneね

```Haskell
None >>= (\x -> Some "!" >>= (\y -> Some (show x ++ "!")))
-- None

Some 3 >>= (\x -> None >>= (\y -> Some (show x ++ "!")))
-- None
```

これを

```Haskell
foo = do
    x <- Some 3
    y <- Some "!"
    Some (show x ++ y)
```

こう書けるってのがdo記法らしい

まるで何も考えずにOptをはがしている様に見えるけど、do全体がOptの文脈内なので大丈夫、って感じかな

```
ghci> foo
Some: 7
```

`>>=`と同じように、一部にNoneが入ったら最終的にはNoneにちゃんとなる

```Haskell
bar = do
    x <- Some 3
    y <- None
    Some (show x ++ y)
```

```
ghci> bar
None
```

### 疑問: ApplicativeFunctorとの使い分け
でもさっきの例だと

```Haskell
(\x y -> show x ++ y) <$> Just 3 <*> Just "!"
```

でも同じ結果だよね
つまりApplicativeFunctorで十分って事？

[Applicativeのススメ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20101211/1292021817)という今まで何度か見た記事にはApplicativeFunctorで良いよ、って書いてある（と思う）
慣れと状況次第、ってところもあるのかな？
（余談だけど、この記事が読める様になっていてとても嬉しいｗ）

### 疑問: IO
OptもIOもEitherも、なんかの文脈を付与しているって点では同列なんだな、って思ってきた
で、IOって文脈は、外の世界とやりとりできるって文脈ってことでおｋ？

```Haskell
baz :: IO Int
baz = do
    print "hoge"
    return 5
```

どこにもSomeって書いてないけど、Optの文脈だと型注釈を付ければ`Some 5`が得られる

```Haskell
poo :: Opt Int
poo = do
    return 5
```

で、pooでprintを書いてみると

```Haskell
poo :: Maybe Int
poo = do
    print "hoge"
    return 5
```

怒られた、うん、知ってた
Maybeの文脈でIOは出来ないぞ、的なことを言われた気がする

逆のIOの文脈でMaybeでも怒られた

```Haskell
zak :: IO Int
zak = do
    print "hoge"
    x <- Just 5
    return 5
```

でもこれなら怒られない

```Haskell
zak :: IO Int
zak = do
    print "hoge"
    print $ Just 5
    return 5
```

ただ値の様に扱うのは良くて、`<-`を使ってひっぺがすのは違う文脈の中では出来ない、って感じなのかな？

## まとめ
まだまだ入り口って感じだけど、相当理解度があがった実感があるのでここまでで一区切りとするよ

学習って観点で大きく思ったことが2つ

+ 絵とか例え話とかじゃあなくて、もうズバリ型をばーんと見せられるのが一番素直に理解できる気がした
+ そしてその点で言うとH本は本当にわかりやすいと思った
 + ただ目次的には`Functor`, `ApplicativeFunctor`, `Monad`は別に連続していないので、一気に理解したいぜ！ってのには向かないかも？

### 3つのまとめ（再掲）
3つの肝となる型をもう一度

Functor: 関数を、文脈のある値に適用できる

```Haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

```Haskell
fmap (+2) (Some 5)
-- Some: 7
```

ApplicativeFunctor: 文脈のある関数を、文脈のある値に適用できる

```Haskell
class (Functor f) => Applicative f where
    pure :: a -> f a

    (<*>) :: f (a -> b) -> f a -> f b
```

```Haskell
pure (+) <*> Some 2 <*> Some 3
-- Some 5
```

Monad: 文脈のある値を、文脈を付けて返す関数に適用する

```Haskell
class Monad m where
    return :: a -> m a

    (>>=) :: m a -> (a -> m b) -> m b

    -- (>>) と fail は略
```

```Haskell
let optInc x = Some $ x + 1

return 5 >>= optInc 
-- Some: 6
```

### 今後の課題
とりあえず、気になっていること

+ H本の`Monoid`の部分、飛ばしちゃった:p
+ `State`モナド等
+ たまに見る`lift`って何？
+ モナドトランスフォーマーって何？

今までの「勘で`>>=`とか`<$>`とか使ってみて怒られる」という状態は脱したｗ
あとは経験あるのみ、かな？

ひとつふわっとした事が無くなってレベルアップした気がするので、とても満足
ではﾉｼ
