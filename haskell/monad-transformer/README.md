Haskell 色んなモナドとモナド変換子

前にH本をなぞってFunctorからMonadまで勉強して、[まとめ記事](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3)を書きました。
その後モナド変換子が必要になった時に手が止まってしまったので、その辺りのことをまとめます。

ちなみにまとめて記事を投稿しているのは大体以下の動機によるものです。

+ 嘘はつけないのでなんとなくの理解をしっかりの理解にしようと言う気持ちになる
+ 間違っていると指摘がもらえる可能性がある
+ 学習記録
+ 数年後自分で見て笑う（結構面白いんだこれがｗ）

あ、そうそう、風邪引いたので今日のお題は風邪引いたときにやることです。

## 前置き
### H本について
H本ではFunctor, ApplicativeFunctor, Monadについて記載されています。
Monadの部分で例コードの比率が多いのはMaybe（ピエールが綱渡りするやつ）な印象です。

WriterモナドやStateモナド等は終盤にさらっと出てきますが、他の章ほど腹落ちしきらない感じがしました。

WebやGitHubでコードを見ていると見かける`liftIO`や`StateT`の様な関数の説明も無かった気がします。（少なくとも索引にはなかった）


なので、「これで俺もモナド使える様になったぜー」ってなんか書いてみてモナド変換子が必要になり
「あ...あれ...話が違うよH本...」みたいな気分になります。なりましたｗ

### 現状
+ IOモナドと失敗系モナドは使える
+ WriterとかStateは必要になったらggrば良いと思っている
+ 取り急ぎIOモナドと失敗系モナドを両方使いたい、モナド変換子が必要っぽい
+ モナド変換子とかで軽くggrと大抵Stateモナドとかわかってる前提でよくわからない

### ゴール
+ まず失敗系以外のモナドをも触ってみる
 + Stateモナドを使える様になりたい
+ とりあえずモナド変換子が使える様になり、IO失敗モナドが書ける様になる
+ 新しいモナドを作ったり変換子を作る気はない

## モナド
とりあえず何種類か書いてみる
（引数の型がほぼ自作ですが、ほぼ全部Stringの型シノニムですので基本的には記載を省略します）

### IO
外部システムとのやりとりを行います
主にDBアクセスや文字やファイルの入出力の際に用います

今回は病欠メールを送ったり、病院を探したりそれが営業中かを調べたりします

```Haskell:IO.hs
sendMail :: MailBody -> IO ()
sendMail = putStrLn

findHospital :: Address -> IO HospitalName
findHospital address = return $ address ++ "病院"

isOpen :: HospitalName -> IO Bool
isOpen name = return True

goOr :: Bool -> IO ()
goOr isFound
    | True  = putStrLn "病院行く"
    | False = putStrLn "病院無かった..."
```

do記法でつなげるとこんな感じです
IOの文脈のdoの中では、まるで`<-`でIOを引っぺがしてStringを手に入れている様に使えます

```Haskell:Main.hs
_io :: IO ()
_io = do
    sendMail "会社休みます"
    name <- findHospital "日本"
    b <- isOpen name
    goOr b
```

用意したのは全て値をモナド値にするアクション(`a -> m b`)なので、bind(`>>= :: m b -> (b -> m c) -> m c`)で繋げられます
（型はイメージ）

```Haskel:Main.hs
_io2 :: IO ()
_io2 = do
    sendMail "会社休みます"
    findHospital "日本" >>= isOpen >>= goOr
```

```Haskell:ghci
_io
会社休みます
病院行く
```

この辺は軽い復習〜

### Either
失敗系モナドです
Maybeモナドと違い、失敗時にも値（大抵は理由）を返せます

病院に行って処方箋をもらい、処方箋を薬局で薬にします

```Haskell:Either.hs
goHospital :: HospitalName -> Either String Prescription
goHospital name = Right "prescription"

getMedicine :: Prescription -> Either String Medicine
getMedicine prescription = Right "medicine"

goHospital' :: HospitalName -> Either String Prescription
goHospital' name = Left "dont need"
```

これらも同様にEitherの文脈のdoの中で引っぺがしたり、bindで繋いだり出来ます

```Haskell:Main.hs
_either :: Either String Medicine
_either = do
    prescription <- goHospital "日本病院"
    getMedicine prescription


_either2 :: Either String Medicine
_either2 = do
    goHospital "日本病院" >>= getMedicine
```

薬が手に入りました

```Haksell:repl
_either
Right "medicine"
```

薬なんかいらねーよ！と処方箋をもらえなかった場合は

```Haskell:Main.hs
_either3 :: Either String Medicine
_either3 = do
    goHospital' "日本病院" >>= getMedicine
```

薬が手に入りません（失敗）

```Haskell:repl
_either3
Left "dont need"
```

失敗したのは`goHospital'`で、`getMedicine`は`Right`しか返さないのに、ちゃんと繋げると最終結果が失敗する
その辺りの理由はEitherの`Monad`の実装を見るとわかる

```Haskell
instance (Error e) => Monad (Either e) where
    return x = Right x
    Right x >>= f = f x
    Left err >>= f = Left err
    fail msg = Left (strMsg msg)
```

前の計算が失敗していたら次の処理は呼んですらいないのが実装を見るとよくわかる

この辺も習得済みなので、まだ復習の範囲内〜

### Writer
こっから先は初見！状態系モナドって言うのかな？

値と一緒にログを残すらしい
今回は熱を測ってみよう、で、測った時間と平均体温でもだしてみよう

#### まずは型を見る
なんかわかった気になれるので、まずはghciで`:t`して型を見る！

Writerモナドのコンストラクタは`Right`みたいに公開されていないので、`writer`という関数で生成する
タプルを渡すっぽい

```Haskell:repl
:t writer
writer :: MonadWriter w m => (a, w) -> m a
```

で、Writerは`runWriter`というタプルの属性を持っている
値は当然`writer`で渡したタプルだろうな

```Haskell
newtype Writer w a = Writer { runWriter :: (a, w) } 
```

それの型は当然こう
`writer`で突っ込んだのが`runWriter`で取れるってことだね！

```Haskell:repl
:t runWriter
runWriter :: Writer w a -> (a, w)
```

だから、なんか急に`runWriter`とか出てきたりWriterはコンストラクタが無いとか言われてビビるけど、
所詮タプルのラッパーじゃないか！って程度に緩く臨めば良いんじゃあないかな、って思った
（まぁ実際`newtype`で出来てるし、実装上は本当にただのラッパーなんだろう）

ただの値の出し入れだし、実際やってることこれと同じレベルだよね？

```Haskell:repl
data Mail = Mail { body :: String } deriving Show

body $ Mail "hello"
"hello"
```

#### 使ってみる
もうそんなに恐くないぞ？

```Haskell:Writer.hs
import Control.Monad.Writer

measure :: Temperature -> Writer [TemperatureLog] Temperature
measure temperature = writer (temperature, ["temperature: " ++ show temperature])

measureAt :: Temperature -> Time -> Writer [TemperatureLog] Temperature
measureAt temperature time = writer (temperature, ["temperature: " ++ show temperature ++ " at " ++ time])
```

Writerモナドを作って、`runWriter`で値を取り出すと、ただのタプルが手に入る

```Haskell:repl
runWriter $ measure 37.4
(37.4,["temperature: 37.4"])
```

なんとなく適当にbindしてみたらこうなった

```Haskell:repl
runWriter $ measure 37.4 >>= measure
(37.4,["temperature: 37.4","temperature: 37.4"])
```

これがちょっと不思議に見えた
`measure`は数値しか受けないし、`writer`はただタプルを`Writer`にするだけなのに、どこで状態引き継ぎが行われたんだろう？？って

しかしそこを「なんか謎！」で済ますわけにはいくまいてー、なんて思って`(>>=)`の実装を見たら案外スッキリわかった

```Haskell
instance (Monoid w) => Monad (Writer w) where
    return x = Writer (x, mempty)
    (Writer (x, v)) >>= f = let (Writer (y, v')) = f x
                             in Writer (y, v `mappend` v')
```

`measure`の例の場合、`f`が流し込み先(`measure`)で`x`が前の結果の値の方(`37.4`)で`v`が前の結果のログの方(`["temperature: 37.4"]`)だよな？
なーんだ、次の計算に値を渡して出来た2つめのWriterに前のログくっつけてるだけかー

do記法の魔術のなかでログの保持と破壊的代入でもしてるのかと勝手に思ってたけど、どっちかって言うと`Immutable Object`みたいな感じなんだな！

はははーもう使えそうだ！do記法行ってみよー

Writerモナドを手に入れる関数

```Haskell:Main.hs
aveAs3 :: Double -> Double -> Double -> Double
aveAs3 a b c = (a + b + c) / 3

_writer :: Writer [TemperatureLog] Temperature
_writer = do
    a <- measure 37.5
    b <- measure 37.2
    c <- measure 37.8

    return $ aveAs3 a b c
```

これでもコード的には正しいけど、別におもしろくないな
折角だしそれっぽいログを付けよう

時間を残せる`measureAt`の方を使って、`runWriter`も使って値を返そう
do内がWriterモナドの文脈なので、`runWriter $ do`になるはず

```Haskell:Main.hs
_writer2 :: (Temperature, [TemperatureLog])
_writer2 = runWriter $ do
    a <- measureAt 37.5 "07:00"
    b <- measureAt 37.2 "12:00"
    c <- measureAt 37.8 "15:00"

    return $ aveAs3 a b c
```

```Haskell:repl
_writer2
(37.5,["temperature: 37.5 at 07:00","temperature: 37.2 at 12:00","temperature: 37.8 at 15:00"])
```

とりあえず使える様にはなった気がするのでOK！

### State
なんか難関っぽいけどやってみよう！こいつも状態系モナドだ

状態遷移を実装するのに使う様な？
今回は風邪を引いたり薬を飲んで直したりする様を実装してみよう

#### まずは型を見る
こちらもまずは`:t`で型を見る！

StateもWriterと同じくコンストラクタは公開されていないので、`state`という関数で生成する
今度は何やら関数を渡すらしい！

```Haskell:repl
:t state
state :: MonadState s m => (s -> (a, s)) -> m a
```

Writerモナドが`runWriter`という属性名で値を保持している様に、Stateモナドは`runState`という属性名で先ほど与えた一引数関数を保持している様だ

```Haskell
newtype State s a = State { runState :: s -> (a, s) }
```

`runState`はただの属性のアクセサなので恐くなどないぞ！

```Haskell:repl
:t runState
runState :: State s a -> s -> (a, s)
```

ふふん、なんだWriterと全然変わらないじゃあないか

#### 使ってみる
風邪を引いたり薬を飲んだり、またちょっと風邪を引きかけたりする
3回目の服用で直るけど、その途中でまた風邪を引きかけると悪い状態に戻る（平時では風邪にならないで済む）

```Haskell:State.hs
import Control.Monad.State

data Health = Good | Taking | Bad deriving (Eq, Show)

haveACold :: State Health Message
haveACold = state $ (\_ -> ("oops...", Bad))

takeMedicine :: Int -> State Health Message
takeMedicine times = state $ (\_ -> ("taken " ++ show times ++ " times", health times))
    where
        health :: Int -> Health
        health times
            | times < 3  = Taking
            | otherwise  = Good

littleCold :: State Health Message
littleCold = state f
    where
        f :: Health -> (Message, Health)
        f Good = ("do not mind!", Good)
        f _    = ("oops... have again...", Bad)
```

Writerモナドの時みたいに、とりあえず`runState`って関数にStateモナド渡せば良いんでしょ？

```Haskell:repl
runState haveACold 

<interactive>:62:1: error:
    • No instance for (Show (Health -> (Message, Health)))
        arising from a use of ‘print’
        (maybe you haven't applied a function to enough arguments?)
    • In a stmt of an interactive GHCi command: print it
```

しまった...`runState`で取れるのはWriterの時と違い関数だった...そりゃあ`show`出来ないよねー

取れた関数に`Health`を適用すると、`(Message, Health)`が手に入るんだった

```Haskell:repl
runState haveACold Good 
("oops...",Bad)
```

これまず一引数関数を手に入れて、次に残りを適用するってことだから、こんな感じと似てるな

```Haskell:repl
(+) 3 5
8
```

ということは、`runState`を間に置けるかな？

```Haskell:repl
haveACold `runState` Good 
("oops...",Bad)
```

置けた！意味があるかはわからないけどｗ

`runState`で手に入るのが`state`に渡した関数である、とちゃんとわかると`littleCold`がちゃんと理解できる

```Haskell:State.hs（再掲）
littleCold :: State Health Message
littleCold = state f
    where
        f :: Health -> (Message, Health)
        f Good = ("do not mind!", Good)
        f _    = ("oops... have again...", Bad)
```

ただサンプルをコピペしてた時は
`littleCold`って引数ないのに`f :: Health ->`の`Health`っていつ手に入れたんだーって混乱していた
けど、実はまだ手に入っていなくて、`runState`で取り出したこの`f`に自分で渡すんだな

こっちもなんかdoのすごい魔術でどこからかいつの間にか`Health`が渡されてくるんだと思っていた
というかStateモナドって「変えた状態を返す」と思っていたけど、「状態の変え方を返す」と理解した
State（状態という意味の英単語）と言うくらいだから状態を保持していると思っていたけど、保持しているのはルールなんだなーと思った

そこまで認識を整理して書いたのが`State.hs`で、これには3パターンの関数を作ってみている

+ `haveACold`は状態分岐も無く強制的に一律の遷移をさせる例
+ `takeMedicine`は引数次第で遷移先が変わる例
+ `littleCold`は遷移元の状態次第で遷移先が変わる例

doでくっつけて使ってみよう

```Haskell:Main.hs
_state :: Int -> State Health Message
_state times = do
    haveACold
    takeMedicine times
    littleCold
```

服用が3回だと完治するのでちょっとの寒気など問題なく、2回だと直りきっていないのでまた風邪がぶり返すって感じ

```Haskell:repl
runState (_state 3) Good 
("dont mind!",Good)

runState (_state 2) Good 
("oops... have again...",Bad)
```

うん、とりあえず使える様になった！
