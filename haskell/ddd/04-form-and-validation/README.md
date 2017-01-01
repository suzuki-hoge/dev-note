DDDをHaskellで考える フォームとバリデーション
DDD初心者が拙いHaskellを使って色々考える試みです。

## はじめに
先日[DDDをHaskellで考える 失敗を表現する](http://qiita.com/suzuki-hoge/items/5b56c7248edaeb81ef2f)という記事を投稿しました。
今回はその中で「バリデーションはまたいつか」としておいた部分について考えます。

> 例えばAPIを作っていて、飛んできたパラメータの桁やフォーマットが正しく無い場合、それは例外でしょうか？
> 
> 曖昧な表現ですが、受け取ってチェックする以上想定しているとも思えるし、外の世界との窓口はシステマチックな話とも思えます。
> 
> フォーム部品についてもいずれ試し書きをしてみたいと思っていますが、今は以下の様に`Either`を使った`関数`にしたいと思っています。
> 理由はまた改めて述べる機会を作りたいと思います。

## Haskellについて
手前味噌ですが僕が今回の試みにあたり軸に考えている部分を[最初の投稿](http://qiita.com/suzuki-hoge/items/82229b903655ca4b5c9b)に載せています。

## 例外にしない理由
一言で言うと例外より`Either`の方が扱いやすいからです。

また、例外にしてしまうと最初に不備を見つけた時点で残りの検査が終わってしまうと考えました。
それだと複数の不備をまとめて指摘できないですし、出る例外がコードの順番に依存すると考えました。

### Data.Either.Validation
`Either`で試し書きをしていたときに、`Data.Either.Validation`というモジュールがあることを教えてもらいました。
`Validation`は一言で言うと、全部のエラーを溜められる`Either`です。

`Either`では最初に出てきた失敗を保持し続けるのみですが、

```Haskell:repl
(+) <$> Right 5 <*> Right 3
Right 8

(+) <$> Left ["error 1"] <*> Left ["error 2"]
Left ["error 1"]
```

`Validation`では全ての失敗を連結してくれます。

```Haskell:repl
(+) <$> Success 5 <*> Success 3
Success 8

(+) <$> Failure ["error 1"] <*> Failure ["error 2"]
Failure ["error 1","error 2"]
```

`Validation`の使い方や今回のコードの元ネタは[HaskellのData.Either.Validationを使う](http://qiita.com/suzuki-hoge/items/5178acebb020bc8a519b)にまとめてありますので、良ければご覧ください。

## 実例
いつもは素の`.hs`ファイルですが、今回は`stack new`をしてみました。
テストの依存ライブラリに`hspec`を追加して、テストも書きます。

テストを書きながら小さな関数群を組み合わせていく様を表現できたら良いと思います。

### 例題
例によってお題を設けます。

今回は個人情報登録フォームから「氏・名」、「生年月日」、「メールアドレス」を受けて、「個人情報」を組み上げるのをお題とします。

### バリデートの共通部品
最初に共通で必要になりそうな関数を作ります。

#### 型シノニム
まず、型シノニムを使ってただの文字列にエイリアスを用意し、可読性を上げます。

```Haskell:Validator.hs
type FormName = String
type Value = String
type Message = String
type Error = String
type Validated a = Validation [Error] a
type Rule = FormName -> Value -> Validated Value
```

先の記事とは少し違い、`Validated`は型引数を取る様にしてみました。
`Validated Value`や`Validated FirstName`の様に使います。

#### ルール
次にチェック関数を沢山用意します。
今後これを`ルール`と呼びます。

```Haskell:Validator.hs（より一部抜粋）
notEmpty :: Rule
notEmpty name value
    | value /= "" = Success value
    | otherwise   = Failure $ mkErrors name value "empty string is not allowed"

lenIn :: Int -> Int -> Rule
lenIn x y name value
    | length value `elem` [x..y] = Success value
    | otherwise         = Failure $ mkErrors name value $ "allowed length is " ++ show x ++ " to " ++ show y
```

#### バリデートとValueObject生成
最後に、バリデーションの実行と`ValueObject`の生成を行う部品を用意します。

```Haskell:Validator.hs
parse :: FormName -> [Rule] -> (Value -> a) -> Value -> Validated a
parse name rules constructor value = constructor <$> validate name rules value
    where
        validate :: FormName -> [Rule] -> Value -> Validated Value
        validate name rules value = head <$> sequenceA (map (\f -> f name) rules <*> [value])
```

少し長いですが、型シノニムのおかげで読めそうです。
適当な`ValueObject`を用意してそれで試してみましょう。

```Haskell:repl
data FooId = FooId String deriving Show

Form.Validator.parse "FooId" [notEmpty, lenIn 3 5] FooId "foo-1"
Success (FooId "foo-1")

Form.Validator.parse "FooId" [notEmpty, lenIn 3 5] FooId "foo-123"
Failure ["FooId[foo-123]: allowed length is 3 to 5"]

Form.Validator.parse "FooId" [notEmpty, lenIn 3 5] FooId ""
Failure ["FooId[]: empty string is not allowed","FooId[]: allowed length is 3 to 5"]
```

とある1つの`ValueObject`に対して複数のルールでバリデーションしています。
失敗時は複数のエラーが、成功時は`Validated FooId`が返されています。

（`head <$> sequenceA ...`の部分は`[Validation [Error] Value]`を`Validation [Error] Value`に平らにしている部分です。
　先の記事では`flat`という関数で畳み込みましたが、その後もらった指摘を反映して`sequenceA`を用いています。）

`stack ghci`で動作確認をしていますが、`REPL`は本当に良いですね。
こういう単体の関数をたくさん作って動作確認する様な開発と`REPL`は本当に相性が良いです。

#### Test
ルールの部分は是非テストを書いておきましょう。

関数単体での動作を保証しておけば`notEmpty`が正しく動くか確かめるために試しにAPIを呼んでみるなんて必要はありません。

```ValidatorSpec.hs（より一部抜粋）
spec :: Spec
spec = do
    describe "notEmpty" $ do
        it "success" $
            notEmpty "FooForm" "foo" `shouldBe` Success "foo"

        it "failure" $
            notEmpty "FooForm" ""    `shouldBe` Failure ["FooForm[]: empty string is not allowed"]

    describe "lenIn" $ do
        it "success" $
            lenIn 2 3 "FooForm" "foo"  `shouldBe` Success "foo"

        it "failure" $
            lenIn 2 3 "FooForm" "fooo" `shouldBe` Failure ["FooForm[fooo]: allowed length is 2 to 3"]
```

### 単一要素のValueObjectとForm
さて、ルールとそれを適用する関数が出来たので、今度は`ValueObject`とそれの`Form`を作りましょう。

ここでの`ValueObject`は単一の要素からなるとし、便宜上`単一要素のValueObject`と言います。
また`Form`は`ValueObject`と基本的には1:1で存在するとします。
（異なるURLで同一の`ValueObject`に違うルールを適用する場合は違う`Form`を作ることになると思いますが）

#### ValueObject
これだけです。

```Haskell:FirstName.hs
module Domain.User.FirstName where

data FirstName = FirstName String deriving (Show, Eq)
```

#### Form
こちらもこれだけです、実質1行ですね。

```Haskell:FirstNameForm.hs
module Form.User.FirstNameForm where

import Form.Validator as V
import Domain.User.FirstName

parse :: Value -> Validated FirstName
parse = V.parse "FirstName" [notEmpty, lenIn 3 8] FirstName
```

これだけで複数ルールのチェックと、全てのエラーの保持もしくはバリデーション済み`ValueObject`が手に入ります。
型を`Value -> Validated FirstName`と表現できたところがちょっとポイントです。

### Test
バリデート済みの`FirstName`、もしくは複数のエラーが得られることをテストします。

```Haskell:FirstNameFormSpec.hs
spec :: Spec
spec =
    describe "parse" $ do
        it "success" $
            parse "John" `shouldBe` Success (FirstName "John")

        it "failure empty value" $
            parse "" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
            ]
```

### 複数要素のValueObjectとForms
`単一要素のValueObject`は正しくバリデーション出来ました。

次は`複数要素のValueObject`をバリデートしてみます。（こちらも便宜上そう呼んでいますが、不適切でしたら訂正します）
`複数要素のValueObject`とは、例えば「氏と名から成るフルネーム」の様な`ValueObject`を指すとします。

#### ValueObject
これだけです。
`LastName`は先述の`FirstName`とほぼ同様の実装です。

```Haskell:FirstName.hs
module Domain.User.FullName where

import Domain.User.FirstName
import Domain.User.LastName

data FullName = FullName FirstName LastName deriving (Show, Eq)
```

`FullName`は2引数関数で、`FirstName`と`LastName`を受けます。

```Haskell:prel
FullName (FirstName "John") (LastName "Doe")
```

#### Forms
バリデート済みの`複数要素のValueObject`を得るのは簡単です。

```Haskell:FullNameForms.hs
module Form.User.FullNameForms where

import Form.Validator

import Domain.User.FullName
import Form.User.FirstNameForm as F
import Form.User.LastNameForm as L

parse :: Value -> Value -> Validated FullName
parse first last = FullName <$> F.parse first <*> L.parse last
```

先に`FullName`は2引数関数だと述べましたが、その関数にバリデート済みの氏と名を適用するだけです。

`?.parse`は例えば`Success ValueObject`を返すので、読み替えるとこんな感じです。

```Haskell:repl
FullName <$> Success (FirstName "John") <*> Success (LastName "Doe")
Success (FullName (FirstName "John") (LastName "Doe"))
```

これは2引数関数に`Validation`を適用しているので、冒頭の`(+)`の例と全く同じです。

```Haskell:repl
(+) <$> Success 5 <*> Success 3
Success 8
```

また、細かいですが複数の`Form`を扱う場合は`Forms`と名付けています。

#### Test
`FullNameForms`にはロジックは実質入っていない様なものなのでちょっと過剰な気もしますが、折角なので書いてみます。

```Haskell:FullNameFormsSpec.hs
spec :: Spec
spec =
    describe "parse" $ do
        it "success" $
            parse "John" "Doe" `shouldBe` Success (FullName (FirstName "John") (LastName "Doe"))

        it "failure empty last name" $
            parse "John" "" `shouldBe` Failure [
                "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
            ]

        it "failure empty both name" $
            parse "kz" "" `shouldBe` Failure [
                "FirstName[kz]: allowed length is 3 to 8"
              , "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
            ]
```

ちゃんとバリデート済みのフルネーム、もしくは出た全てのエラーが得られています。

行数は長いですが、大したことはしていません。

### 個人情報を組みあげる
`複数要素のValueObject`は複数の`Validated a`からなる`Validated a`でした。
ですので、`複数要素のValueObject`のネストも可能です。

ここまで来ればもうあとは消化試合です。

#### ValueObject
複数の色々な`ValueObject`から成ります。

```Haskell:PersonalData.hs
module Domain.Registration.PersonalData where

import Domain.User.FullName
import Domain.User.BirthDate
import Domain.Mail.MailAddress

data PersonalData = PersonalData FullName BirthDate MailAddress deriving (Show, Eq)
```

（この記事には載せていませんが、`FullName`は`FirstName`と`LastName`から成る`複数要素のValueObject`、`MailAddress`と`BirthDate`は`単一要素のValueObject`です。
　`MailAddress`は共通ルール以外の独自のルール定義を、`BirthDate`は`String`以外の要素をそれぞれ試したかったので書きました。
　最終的な全容は最後にGitHubのリンクを掲載します。）

#### Forms
複数要素を扱うのでこれも`Forms`と呼びます。

```Haskell:PersonalDataForms.hs
module Form.Registration.PersonalDataForms where

import Form.Validator

import Domain.Registration.PersonalData
import Form.User.FullNameForms as F
import Form.User.BirthDateForm as B
import Form.Mail.MailAddressForm as M

parse :: Value -> Value -> Value -> Value -> Validated PersonalData
parse first last birth mail = PersonalData <$> F.parse first last <*> B.parse birth <*> M.parse mail
```

単一にしろ複数にしろ、`?.parse`は`Validated a`を返すので、いくらでもネストが可能です。
簡単かつシンプルですね。

#### Test
冗長すぎる気がしますが、一応書きます。

```Haskell:PersonalDataFormsSpec.hs
spec :: Spec
spec =
    describe "parse" $ do
        it "success" $ do
            let full = FullName (FirstName "John") (LastName "Doe")
            let birth = B.fromString "1990-01/23"
            let mail = MailAddress "foo.bar@gmail.com"

            parse "John" "Doe" "1990-01/23" "foo.bar@gmail.com" `shouldBe` Success (PersonalData full birth mail)

        it "failure with one error" $
            parse "John" "Doe" "1990-12/34" "foo.bar@gmail.com" `shouldBe` Failure [
                "BirthDate[1990-12/34]: allowed format is %Y-%m/%d, and it must be exist date"
            ]

        it "failure with more than two errors" $
            parse "" "" "" "" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
              , "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
              , "BirthDate[]: allowed format is %Y-%m/%d, and it must be exist date"
              , "MailAddress[]: empty string is not allowed"
              , "MailAddress[]: atmark must be there"
            ]
```

それぞれの`Form`、もしくは`Forms`のエラー全てが得られています。

## 締め
今回の「フォームとバリデーション」についてはここまでとします。

[Haskell力アップ](http://qiita.com/suzuki-hoge/items/36b74d6daed9cd837bb3)、[Validationについて](http://qiita.com/suzuki-hoge/items/5178acebb020bc8a519b)と経由してきたので、個人的には結構満足な結果が得られました。

### Testについて
今回は愚直に全てのテストを実装しましたが、どの部品のテストをどの様に書くかは規模や状況次第だと思います。

ルールの単体テストを書いているので、`Form`および`Forms`層のテストは冗長な感じがします。

例えば`FirstNameFormSpec`が担保しているのは「設定した複数のルールが何か」で、`FullNameFormsSpec`が担保しているのは「複数エラー全てが手に入ること」です。
前者は目視のレビューでも十分抜けますし、後者ははHaskellの標準ライブラリと言語仕様に基づいた実装なので、テストしないという選択もあると思います。

規模やプロダクトの寿命、メンバーの入れ替わり頻度や改修頻度と相談して、例えば「単一要素の`Form`だけテストする」とか「`PersonalDataForms`だけテストする」とかにするのもありだと思います。

### 最終成果物
今回書いたコードは[GitHub](https://github.com/suzuki-hoge/dev-note/tree/b7b26e1702a9db68578fcc0c61de517fc97f9836/haskell/ddd/04-form-and-validation/form-and-validation)にあります。

### 続きについて
続きは「API層と認証・認可」について考える予定ですが、`IO`と`Validation`が絡んできて今のHaskell力ではうまく書けそうにありません。
ので、少しHaskell力を鍛えてから続けたいと思います。モナド変換子とかを理解しないといけないのでしょうか？

今回はDDDよりHaskell色の強い記事となってしまいましたが、次はこの記事でやったことを絡めつつDDD色強めになる予定です。

ありがとうございました。
