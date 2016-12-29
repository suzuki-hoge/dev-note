HaskellのData.Either.Validationを使う

先日使ってみたいモジュールがあるからと[こんな記事](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3)を書きました。
まぁ記事と言っても殴り書きの自習ノートみたいなもんですが。

で、使うには十分な理解度に到達したと思うので、使いたかった`Data.Either.Validation`を使ってみます。

使おうとしたら全然使用例みつからないし日本語の記事も全くと言って良いほど見当たらなかったので、せっかくだしまとめてみます。

## どんなもの？
一言で言うと、全部のエラーを溜められる`Either`です。
ちなみにインストールは不要です。

これが`Either`の`Applicative`の実装です。
一度失敗したらそれ以降が何であろうと、その失敗を保持し続けます。

```Haskell:Either
instance Applicative (Either e) where
    pure          = Right
    Left  e <*> _ = Left e
    Right f <*> r = fmap f r
```

動かしてみます。

```Haskell
(+) <$> Right 1 <*> Right 2
Right 3

(+) <$> Left "error 1" <*> Right 2
Left "error 1"

(+) <$> Left "error 1" <*> Left "error 2"
Left "error 1"
```

最後に得られるのは最初の失敗だけです。


それに対して`Validation`の実装はこうです。
2つめ以降の失敗の場合に連結しています。

```Haskell:Validation
instance Semigroup e => Applicative (Validation e) where
  pure = Success
  Failure e1 <*> Failure e2 = Failure (e1 <> e2)
  Failure e1 <*> Success _  = Failure e1
  Success _  <*> Failure e2 = Failure e2
  Success f  <*> Success a  = Success (f a)
```

こちらも動かしてみます。

```Haskell
import Data.Either.Validation 

(+) <$> Success 1 <*> Success 2
Success 3

(+) <$> Failure ["error 1"] <*> Success 2
Failure ["error 1"]

(+) <$> Failure ["error 1"] <*> Failure ["error 2"]
Failure ["error 1","error 2"]
```

## 実例イメージ
4つのパラメータを受けて、全てのバリデーションが通ったら購入処理を行ってみます。

```Haskell:購入処理
import Text.Printf

purchase :: String -> String -> String -> Int -> String
purchase userId mailAddress itemName itemCount = printf "ordered [userId: %s, mailAddress: %s, itemName: %s, itemCount: %d]" userId mailAddress itemName itemCount
```

手抜きで文字列連結をするだけですが、今回の本体です。
どこにもバリデーションに関することは現れていません。

```Haskell
purchase "user-1" "foo@bar.com" "item-1" 3
"ordered [userId: user-1, mailAddress: foo@bar.com, itemName: item-1, itemCount: 3]"
```

ただの値を渡すとただの値が返ってくる関数です。

さて、この4つのパラメータのバリデータを書いてみます。

```Haskell:バリデータ
import Data.Either.Validation

validateUserId :: String -> Validation [String] String
validateUserId value = if value /= ""
    then Success value
    else Failure ["UserId: empty not allowed"]

validateMailAddress :: String -> Validation [String] String
validateMailAddress value = if '@' `elem` value
    then Success value
    else Failure ["AailAddress: no atmark"]

validateItemName :: String -> Validation [String] String
validateItemName value = if value /= ""
    then Success value
    else Failure ["ItemName: empty not allowed"]

validateItemCount :: Int -> Validation [String] Int
validateItemCount value = if value /= 0
    then Success value
    else Failure ["ItemCount: zero not allowed"]
```

1項目につき1つのルールでチェックします。

```Haskell
validateUserId ""
Failure ["UserId: empty not allowed"]

validateUserId "user-1"
Success "user-1"

validateMailAddress "foo.bar.com"
Failure ["AailAddress: no atmark"]

validateMailAddress "foo@bar.com"
Success "foo@bar.com"

validateItemName ""
Failure ["ItemName: empty not allowed"]

validateItemName "item-1"
Success "item-1"

validateItemCount 0
Failure ["ItemCount: zero not allowed"]

validateItemCount 3
Success 3
```

本文とバリデータは揃いました。

あとはバリデート結果が全部`Success`かチェックして、その時だけ`Success`が保持している値を引っ張りだして本文を呼ぶ...
なんて面倒な事はしませんよ！

`Validation`は`Applicative`なので、ただの値を受け取る`purchase`をそのまま使います！

```Haskell
purchase <$> validateUserId "user-1" <*> validateMailAddress "foo@bar.com" <*> validateItemName "item-1" <*> validateItemCount 3
Success "ordered [userId: user-1, mailAddress: foo@bar.com, itemName: item-1, itemCount: 3]"

purchase <$> validateUserId "" <*> validateMailAddress "foo@bar.com" <*> validateItemName "item-1" <*> validateItemCount 0
Failure ["UserId: empty not allowed","ItemCount: zero not allowed"]
```

全てのバリデーションが通ったときは`purchase`の結果が、1つ以上のバリデーションエラーがある場合は出たエラー全てが得られます！

これすごくない！？

`purchase`自体の単体テストをする場合なんかはそのまま`String`とかを渡して、プロダクトコードで使うときは`Validation`を渡す（風）に使えちゃいます。
エラーがあったら〜、なかったら〜、という処理はHaskellの標準ライブラリで実現しているのでテスト書かないで良いでしょう。

バリデータと本文の単体テストだけをすれば良いんです！

なんて簡単！
型注釈と`if`の改行を考えないで実質行数で考えると5行しか書いてないです！

以上で`Data.Either.Validation`の紹介を終わります。
ぜひ触ってみてください、感動しますよ！

## 余談
`printf`って引数の数とか型を間違えると実行例外になっちゃうんですね。
Haskellで実行例外出すとものすごーく損した気持ちになるので今後はちゃんと作るときは使わない様にしようと思いました。

## おまけ
せっかく`Validation`は複数のエラーを全部返せるのだから、1つのバリデータにつき1つのルールじゃあなくて複数ルールにしたい。

必須とか文字長は独立部品として用意してみます。

```Haskell:ルール
notNull :: String -> String -> Validation [String] String
notNull name value = if value == "" then Failure [printf "%s: not null" name] else Success value

len :: Int -> String -> String -> Validation [String] String
len size name value = if length value /= size then Failure [printf "%s: length must be %d" name size] else Success value
```

ルールと呼ぶ事にします、こうやって使います。
バリデータから独立させたので、バリデータ名と値を受けて`Validation`を返します。

```Haskell
notNull "UserId" ""
Failure ["UserId: not null"]

len 6 "UserId" "abc"
Failure ["UserId: length must be 6"]
```

さて、これらの部品を全て呼んで、エラーが混じっていたらエラー全てを、正常なら値を返さなければなりません。
こう書いてみました。

```Haskell:バリデータ
validateUserId :: String -> Validation [String] String
validateUserId value = (\v _ -> v) <$> notNull "UserId" value <*> len 6 "UserId" value
```

エラーがあったら〜、なかったら〜、はそのままさっきの`Applicative`と同じ様に出来ますが、`Success`の場合の値はどうしたら良いでしょうか...
全てが`Success`の場合は、全ての`Success`に同じ値(value)が入っているので、ラムダ式で適当に1つだけを取り出してみました。

```Haskell
validateUserId "user-1"
Success "user-1"

validateUserId ""
Failure ["UserId: not null","UserId: length must be 6"]
```

とりあえずは正しそうです。

けどこれだとルールを増やした場合にラムダ式の引数も増やさないといけないので、イケてない感があります。

どうしようか考えていたところで、先日読んだH本のリストの`Applicative`を思い出しました。
あれは確か1引数関数を総当たりで適用出来る感じだったはず...

```Haskell
[(+2), (+3)] <*> [5]
[7,8]
```

お、これ良さそうなのでは？

```Haskell
[notNull "UserId", len 6 "UserId"] <*> [""]
[Failure ["UserId: not null"],Failure ["UserId: length must be 6"]]

[notNull "UserId", len 6 "UserId"] <*> ["user-1"]
[Success "user-1",Success "user-1"]
```

うん、これで進めてみよう。

けどその前に細かいですが、何回もバリデータ名を書くのは嫌だし見通しも悪いので、`map`を使ってまとめて部分適用するようにちょっとだけ改造します。

```Haskell
map (\f -> f "UserId") [notNull, len 6] <*> ["user-1"]
[Success "user-1",Success "user-1"]
```

あとは...やっぱり`[Validation]`を全部のエラーか成功値にまとめないといけないよね...
こんな感じで畳み込んでみようかな...

```Haskell
flat :: Validation [String] String -> Validation [String] String -> Validation [String] String
flat (Success x) (Success y) = Success x
flat (Success x) (Failure y) = Failure y
flat (Failure x) (Success y) = Failure x
flat (Failure x) (Failure y) = Failure $ x ++ y
```

```Haskell
foldl1 flat $ map (\f -> f "UserId") [notNull, len 6] <*> ["user-1"]
Success "user-1"

foldl1 flat $ map (\f -> f "UserId") [notNull, len 6] <*> [""]
Failure ["UserId: not null","UserId: length must be 6"]
```

よし、`Success`か全ての`Failure`に平らに出来てます。

こんな感じで名前をつけてバリデータ名とルールと値を渡すだけで良い様にしておきます。

```Haskell
validate :: String -> [(String -> String -> Validation [String] String)] -> String -> Validation [String] String
validate name rules value = foldl1 flat $ map (\f -> f name) rules <*> [value]
```

これで各バリデータの実装がとてもすっきりして宣言的になりました！

```Haskell:バリデータ
validateUserId :: String -> Validation [String] String
validateUserId = validate "UserId" [notNull, len 6]
```

最後に、下のコードとかを見ると`String`が多すぎてよくわからなくなってきたのでもう一工夫します。

```Haskell
validate :: String -> [(String -> String -> Validation [String] String)] -> String -> Validation [String] String
```

型シノニムを使ってみます。
全部`String`ではあるのですが、エイリアスを付けて別名で書ける様にします。

```Haskell
type FormName = String
type Value = String
type Error = String
type Validated = Validation [Error] Value
type Rule = FormName -> Value -> Validated
```

こうするだけで大分読み易くなります。
（最初掲載したコードに`Int`の部分がありましたが、WebAPIのパラメータは全部`String`なのでまとめてしまいました）

```Haskell
notNull :: Rule

len :: Int -> Rule

flat :: Validated -> Validated -> Validated

validate :: FormName -> [Rule] -> Value -> Validated

validateUserId :: Value -> Validated
```

これでとても読み易くなりました！

バリデーション部分の最終成果物はこんな感じです。
それではまたﾉｼ

```Haskell
import Text.Printf
import Data.Either.Validation

type FormName = String
type Value = String
type Error = String
type Validated = Validation [Error] Value
type Rule = FormName -> Value -> Validated

notNull :: Rule
notNull name value = if value == "" then Failure [printf "%s: not null" name] else Success value

len :: Int -> Rule
len size name value = if length value /= size then Failure [printf "%s: length must be %d" name size] else Success value

flat :: Validated -> Validated -> Validated
flat (Success x) (Success y) = Success x
flat (Success x) (Failure y) = Failure y
flat (Failure x) (Success y) = Failure x
flat (Failure x) (Failure y) = Failure $ x ++ y

validate :: FormName -> [Rule] -> Value -> Validated
validate name rules value = foldl1 flat $ map (\f -> f name) rules <*> [value]

validateUserId :: Value -> Validated
validateUserId = validate "UserId" [notNull, len 6]
```
