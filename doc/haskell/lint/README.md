Haskellの静的解析ツール HLint を使おう

この記事は[Lint Advent Calendar 2016](http://qiita.com/advent-calendar/2016/lint)の23日目の記事です

## はじめに
軽い気持ちでHaskellのリントツールである [HLint](https://github.com/ndmitchell/hlint) を紹介するよ

なかなかHaskellのコードレビューをしてもらう機会ってないと思うんだけど、こいつは結構頼りになる奴なんだ

動作も軽快だし、`stack`使ってるならインストールも一瞬だよ

## 例
### 命名規則
スネークケースをキャメルケースにしろ、って

```Haskell:snake.hs
some_func x = x + 2
```

```
$ hlint snake.hs
snake.hs:1:1: Suggestion: Use camelCase
Found:
  some_func x = ...
Why not:
  someFunc x = ...

1 hint
```

### do
1行の場合の`do`は不要だよ、って

```Haskell:do.hs
check int = case int of
    (Just x) -> do
        putStrLn "just!"
        print x

    Nothing  -> do
        putStrLn "nothing"

main = do
    check (Just 5)
```

```
$ hlint do.hs
do.hs:6:17: Warning: Redundant do
Found:
  do putStrLn "nothing"
Why not:
  putStrLn "nothing"

do.hs:9:8: Warning: Redundant do
Found:
  do check (Just 5)
Why not:
  check (Just 5)

2 hints
```

2箇所出てるね

### そんな関数あるよ
自分で関数組み合わせちゃった場合、まんまそんなメソッドがあると教えてくれる

```Haskell:f.hs
main = print $ take 5 $ repeat 3
```

```
$ hlint f.hs
f.hs:1:16: Warning: Use replicate
Found:
  take 5 $ repeat 3
Why not:
  replicate 5 3

1 hint
```

`repeat 3`は無限に`3`がつまったリストを作り、`take 5`で先頭5つを取り出す、結果`[3, 3, 3, 3, 3]`となる
`replicate 5 3`は`3`を`5`回繰り返してくれるので、やはり`[3, 3, 3, 3, 3]`となる

すげー！

### ポイントフリースタイル
できるよ、って

左辺と右辺の最後の引数が同じ場合は省略できること
`allTwice`に`xs`を渡すのが`map (*2)`に`xs`を渡すのと同じなら、つまり`allTwice`と`map (*2)`は同じ処理、みたいな？

```Haskell:pfs.hs
allTwice xs = map (*2) xs
```

```
$ hlint pfs.hs
pfs.hs:1:1: Warning: Eta reduce
Found:
  allTwice xs = map (* 2) xs
Why not:
  allTwice = map (* 2)

1 hint
```

`allTwice`は`map (* 2)`です、って書くのがCoolだ

### 冗長な無名関数（ラムダ式）
`even`は1つの`Int`を受ける関数で、`\x -> even x`は1つの`Int`を受けて`even`に渡すので、どちらも挙動は同じなんだ

```Haskell:lambda.hs
trimOdd :: [Int] -> [Int]
trimOdd xs = filter (\x -> even x) xs
```

```
$ hlint lambda.hs
lambda.hs:2:1: Warning: Eta reduce
Found:
  trimOdd xs = filter (\ x -> even x) xs
Why not:
  trimOdd = filter (\ x -> even x)

lambda.hs:2:16: Warning: Avoid lambda
Found:
  \ x -> even x
Why not:
  even

2 hints
```

`\x -> even x`は`even`でいいだろ！って出ているし、ついでにさっきのポイントフリースタイルの警告も出ているね

```Haskell:lambda.hs
trimOdd :: [Int] -> [Int]
trimOdd = filter even
```

これで`trimOdd`って関数は`even`で`filter`するよ、って読めるね
こんな感覚で新たな関数を元からある関数を組み合わせるだけで作る、ってのは結構ある

### Data.Function.on
なんか`import`してもいないのに型が合うと「こんな関数あるけどお前なんで使わないの？」って言ってくれる

```Haskell:on.hs
import Data.Function

data Card = Card { value :: Int, label :: String } deriving Show

sameValue x y = value x == value y

main = do
    let card1 = Card 1 "foo"
    let card2 = Card 1 "bar"

    print $ sameValue card1 card2
```

```
$ hlint on.hs
No hints
```

お...およよよよよよ

警告が出なくなってる...`ヽ(´o｀；ﾓｼﾓｼ?`
前と同じ感じで書いてると思うんだけどなー...

ちなみに、前に見た警告は以下みたいなのでした

```
Found:
x y -> value x == value y
Why not:
(==) `Data.Function.on` value
```

なになにわからん
`on`の型はなんじゃろ

```
ghci> :t Data.Function.on
Data.Function.on :: (b -> b -> c) -> (a -> b) -> a -> a -> c
```

なんだこれー
（ちなみに知人に コナミコマンド って言われたｗ）

どうやらこれが

```Haskell
sameValue x y = value x == value y
```

こうできるらしい

```Haskell
sameValue x y = (on (==) value) x y
```

`a`と`a`を`(a -> b)`で`b`と`b`にして、`(b -> b -> c)`で`c`にするんだね
2つの値両方に同じ変換をした上で、その2つを何かにするって感じ

`on`はバッククオートで囲って演算子化して間に置くのがCoolです

```Haskell
sameValue x y = ((==) `on` value) x y
```

そして、いつものポイントフリースタイルで後ろの引数を2つとも消しちゃって

```Haskell
sameValue = (==) `on` value
```

こんな！
`sameValue`とは両方に`value`を適用してから`(==)`するって事だよ　って宣言的になったね！すてき！

## 終わりに
ぶっちゃけ、`on`すげーーー！！！何こんなのまで言ってくれるの！！？？
「なんで`on`つかわねーの？」とか言うけど、そんな標準ライブラリでもない関数シラネーｗｗｗ

って去年くらいの感動をちゃちゃっと書くだけのつもりだったのに、まさかそれが出ないとは...
企画倒れも良いところ...

どなたか理由等わかる方がいたらご教授ください`m(_ _)m`

ただまぁちょっと気まぐれで`HLint`かけるだけでも結構勉強になったりするので、
そういうことが出来るHaskellは「これマジオススメ」ってことで ﾉｼ
