DDDをHaskellで考える 業務ロジックとシステムロジック
DDD初心者が拙いHaskellを使って色々考える試みです。

## はじめに
DDDは会社で見よう見まねで1年実践したけど、DDDの勉強はほぼ一切していないくらい。
Haskellは入門書をなんとか通読できたくらい、けど普段書いてないので全然馴染んでないくらい。

それくらいの奴が1年経ってやっと「ちょっとまじめに考えてみるかぁ」って思って考えたことをまとめる記事です。

記事の主軸はDDDなので、Haskellは読めなくても雰囲気だけ察してもらえると良いな、と思います。

また、Haskellを選んだ理由はこの記事を通して伝えたいと思います。

## Haskellについて
この記事を読むに当たり最低限必要なHaskellの文法を記載します。
僕がDDDを捉えるに当たり用いた考え方が一番含まれる点なので、まとめてみたいと思います。

### 参照透過性と副作用
Haskellには「参照透過性が常に保たれる処理」と「副作用の存在する処理」を別のものとしています。

#### 参照透過性
一言で言うと「同じ引数の場合は必ず同じ戻り値が得られる」処理のことです。

Javaの例で示すと以下の様な感じです。

```Java
public int add2(int x) {
    return x + 2;
}
```

これは引数を`5`で実行したら何度実行しても、何時に実行しても、どんなOSで実行しても、常に`7`が返ります。

#### 副作用
対して副作用は「常に同じ結果が返るとは限らない」とか「他の処理に影響を与える（受ける）」処理のことです。

例えば以下の様な「状況次第では失敗するかも知れない」処理や、

```Groovy
public String fileLines(String path) {
    return new File(path).getText()
}
// groovy です... java でFileIOがあんなに面倒だとは知らなかった...
```

「何らかの値次第で結果が変わり得る」処理は副作用があると言われます。

```Java
public void setShift(int x) {
    shift = x;
}

public int add2AndShift(int x) {
    return x + 2 + shift;
}
```


#### 関数
参照透過性を保証する処理をHaskellでは`関数`と言い、以下の様に定義します。

```Haskell
add2 :: Int -> Int
add2 x = x + 2
```

1行目は関数の型定義（省略可能ですがこの記事では省略しません）、2行目が本文です。
型の部分はとても乱暴に説明すると、`->`の一番右側が「戻り値」、それ以外が「引数」となります。

複数の引数がある場合は以下の様になります。

```Haskell
mkLang :: String -> Int -> String
mkLang lang version = lang ++ show version -- show は所謂 toString
```

これは「引数が`String`と`Int`」で「戻りが`String`」であると示します。

利用する場合は以下の様に引数を半角スペース区切りで渡し、`let xxx =`の形で結果を受け取ります。

```Haskell
let result = add2 5 -- 7
```

```Haskell
let lang = mkLang "java" 8 -- java8
```

#### アクション
対して副作用のある処理をHaskellでは`アクション`と言い、以下の様に定義します。

```Haskell
fileLines :: String -> IO String
fileLines path = do
    readFile path
```

1行目の型定義の戻りに`IO`とついているのが一番の特徴です。（`IO`の他にもありますが記事と関係ないため割愛します）
標準ライブラリの`readFile`の戻りが`IO String`のため、それを最後に行う`fileLines`の戻りも`IO String`となっています。

アクションの結果の値を取り出すには`xxx <-`の形になります。

```Haskell
lines <- fileLines "/path/to/foo/bar.txt"
```

#### 関数からアクションは呼べない
一番のポイントです。

アクションはアクションも関数も呼べますが、関数はアクションを呼べません。
それにより関数には失敗するかも知れない処理が混ざる余地がなく、関数から関数を呼んでも参照透過性が保たれる様になっています。

## 業務ロジックとシステムロジック
DDDについて考えた時、一番最初に次の様に感じました。
「とある要件を満たすプログラムは、大別して2つのロジックから成る」、と。

それらを便宜上「業務ロジック」と「システムロジック」と呼び、考えの根拠を示したいと思います。

### 業務ロジック
業務ロジックとは「仕様に起因して存在する」処理で、「システム都合には依存しない値の変換や条件判断」とします。

例えば「〜〜の場合は購入可能」とか「〜〜を満たせば解約出来る」とか「○と△と□を基に決済情報を組み立てる」とか、その様な処理を指すと考えました。

これ、**全部関数**なのでは？
と思ったのが今回の試みの発端です。

### システムロジック
では対するシステムロジックはどうでしょうか。こちらは**アクション**なのでは？と考えるのは自然だと思います。

こちらはDBアクセスやHttp通信等の「システムを実現するために必要な」処理だと考えました。
そして事実、それらの処理は`IO`を用いなければ実装することは不可能です。

### 例えば？
以下の様な要求があったとします。

「有効な決済情報を登録しているユーザを探し、そのユーザにメールを送信する。件名はユーザ名と契約日時を結合したものである」

どの様な決済情報なら有効なのかはそのプロダクトの仕様に基づき決まりますし、件名もプロダクトの仕様によってその様な結合ルールになっているはずです。
対してユーザを探す部分とメールを送信する部分の実装は別に仕様起因ではなく、外部システムは仕様を実現するためのただの手段だと考えることが出来ます。

### 仮説
全ての業務ロジックは関数であり、そして関数で書けない他全ての処理はシステムロジックなのではないか、という仮説を持ちました。
関数で書けるのであればそれはドメイン層に書くべきであり、ドメイン層ではないところについ書いてしまう関数は実は業務ロジックなのでドメイン層に書くのが適切である。

という仮説です。

## ドメイン層に業務ロジックを集める
この仮説を検証するために制約を考えてみました。

それは「ドメイン層は関数のみで、それ以外の層はアクションのみで実現する。例えばサービス層によく現れる`privateメソッド`の様な処理も、関数で実現できるなら（それは業務ロジックだから）ドメイン層に書く」というルールです。

この仮説を検証するため、今小規模な仕様をお題としてHaskellで実装していますが、レイヤー設計や単体テスト等も気になっており、終えて経験値と納得を得るにはもう少しかかりそうです。

なのでこの記事の残りではありがちなJavaのコードをHaskellに置き換える過程を示すことで、アクションから関数を切り出す様を示してみたいと思います。

また、最初からHaskellで考え実装していたらどうかも示せればと思います。

## 例題
都合の良い適当なお題を考え、あえてJavaで少し悪いコードを書きます。
その次にそれをHaskellに置き換え、少しずつ改善していくことにします。

### お題
ユーザが商品とオプションを購入する

1. ユーザIDと商品とオプションを受ける
+ ユーザIDに該当するユーザが存在しない場合はその旨を返す
+ 商品とオプションの組み合わせが正しくなければその旨を返す
+ ユーザIDに対して商品とオプションを紐づけて永続化する
+ 永続化するとライセンスキーが発行される
+ 件名を「ユーザID + 商品名 + オプション名」としてメールを送信する
+ 受付に成功した場合はライセンスキーを、失敗した場合は理由を返す

商品は以下
+ `PersonalComputer`
+ `Keyboard`

オプションは以下
+ `Backup`
+ `Replacement`

制約は以下
+ オプションは任意項目とする
+ `Backup`は`PersonalComputer`に対してのみ、`Replacement`は`Keyboard`に対してのみ付加可

### Java製
Javaを悪く言うためでは無く、ありがちな悪いコードとして掲載する。

```Java
public class Main {
    public static void main(String[] args) {
        apply("user-id-123", Item.PersonalComputer, Optional.empty());

        apply("user-id-123", Item.PersonalComputer, Optional.of(Option.Backup));

        apply("user-id-123", Item.PersonalComputer, Optional.of(Option.Replacement));

        apply("user-id-123", Item.Keyboard, Optional.of(Option.Backup));
    }

    public static String apply(String userId, Item item, Optional<Option> option) {
        if (findUser(userId) == null) {
            return "ユーザが見つかりません";
        } else if (item == Item.PersonalComputer && option == Optional.of(Option.Replacement)) {
            return "PCに交換オプションは付加出来ません";
        } else if (item == Item.Keyboard && option == Optional.of(Option.Backup)) {
            return "キーボードにバックアップオプションは付加出来ません";
        } else {
            String license = save(userId, item, option);
            sendMail(userId, item, option);
            return license;
        }
    }

    public static String findUser(String userId) {
        return "John";
    }

    public static String save(String userId, Item item, Optional<Option> option) {
        return "license-key-123";
    }

    public static void sendMail(String userId, Item item, Optional<Option> option) {
        System.out.println(userId + " " + item.name() + " " + option.map(Enum::name).orElse(""));
    }
}
```

良くある形だと思う。
この状態だとまだパッと見ても業務ロジックとシステムロジックが混ざっていると言う事自体がわかりづらい。
ついでにまだあえてあんまりクラスは用意していないので、`String`がちらほら見える。

### Haskellに単純に置き換える
出来るだけ同じようにそのまま置き換えてみる

```Haskell
import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq) -- Enum定義

data Option = Backup | Replacement deriving (Show, Eq)

apply :: String -> Item -> Maybe Option -> IO String -- Maybe は Java で言う Optional<>
apply userId item option = do
    user <- findUser userId

    if user == ""
        then return "ユーザが見つかりません"
        else if item == PersonalComputer && option == Just Replacement
            then return "PCに交換オプションは付加出来ません"
            else if item == Keyboard && option == Just Backup
                then return "キーボードにバックアップオプションは付加出来ません"
                else do
                    license <- save userId item option
                    sendMail userId item option
                    return license

findUser :: String -> IO String
findUser userId = return "John"

save :: String -> Item -> Maybe Option -> IO String
save userId item option = return "license-key-123"

sendMail :: String -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStrLn (userId ++ " " ++ show item ++ " " ++ maybe "" show option) -- イメージ的には userId + item.toString + if option.none "" else option.get.toString

main = do
    r1 <- apply "user-id-123" PersonalComputer Nothing
    putStrLn r1

    r2 <- apply "user-id-123" PersonalComputer (Just Backup)
    putStrLn r2

    r3 <- apply "user-id-123" PersonalComputer (Just Replacement)
    putStrLn r3

    r4 <- apply "user-id-123" Keyboard (Just Backup)
    putStrLn r4
```

この時点でJavaの例と大きく違う点は、`IO`が付いているなら副作用があるということがわかる点です。
しかし全てに`IO`が付いています。それでは業務ロジックが存在しないということになってしまうので、少しずつ関数とアクションを切り分けていきましょう。

### とりあえずStringを無くす
でもその前に、折角静的言語なので`String`は全てラップして新しい型を作ることにします。

```Haskell
data UserId = UserId { value :: String } deriving Show

data LicenseKey = LicenseKey { key :: String } deriving Show
```

置き換えてみます。

```Haskell:before
apply :: String -> Item -> Maybe Option -> IO String

findUser :: String -> IO String

save :: String -> Item -> Maybe Option -> IO String

sendMail :: String -> Item -> Maybe Option -> IO ()
```

```Haskell:after
apply :: UserId -> Item -> Maybe Option -> IO String

findUser :: UserId -> IO String

save :: UserId -> Item -> Maybe Option -> IO LicenseKey

sendMail :: UserId -> Item -> Maybe Option -> IO ()
```

こうして見ると`UserId`は全てに現れていますが、`User`と言うものは必要ないみたいです。
`findUser`は`Bool`を返してくれれば十分な様なので変更します。（ここに付いては最後にまた取り上げます）

```Haskell:after
isExist :: UserId -> IO Bool
```

さて唯一残った`apply`の戻りの`String`ですが、ライセンスキーか失敗理由を返さなければ成りません。これは後ほど対応します。

### sendMailの件名組み立てに注目
```Haskell:before
sendMail :: UserId -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStrLn ((show userId) ++ " " ++ show item ++ " " ++ maybe "" show option)
```

というのがあります。
これは「与えられた情報を組み立て」て、「メール送信を実行する」ことを行います。

ここでは手抜きで`putStr`の標準出力でメール送信を代用しますが、文字出力（=ファイル入出力）は副作用があるので`sendMail`の戻りも`IO`になっています。
ですが件名組み立てはどうでしょうか？別に処理を切り出してみます。

```Haskell:after
sendMail :: UserId -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStrLn (mailTitle userId item option)

mailTitle :: UserId -> Item -> Maybe Option -> String
mailTitle userId item option = (show userId) ++ " " ++ show item ++ " " ++ maybe "" show option
```

初めて関数が現れました。
折角なので`mailTitle`の戻りも`String`ではなくて`MailTitle`とでも言う新しい型を作ります。

```Haskell:after2
data MailTitle = MailTitle { title :: String } deriving Show

mailTitle :: UserId -> Item -> Maybe Option -> MailTitle
mailTitle userId item option = MailTitle ((show userId) ++ " " ++ show item ++ " " ++ maybe "" show option)
```

### アクションで関数を用いるのではなく、関数の結果をアクションに渡す
`sendMail`で件名組み立てとメール送信の両方を行うのをやめます。

```Haskell
sendMail :: MailTitle -> IO ()
sendMail title = do
    print title
```

これで`sendMail`は`MailTitle`を受け取り送信するだけになり、組み立てロジックは消えてなくなりました。
`mailTitle`は関数で出来た業務ロジックであり、`sendMail`はアクションで出来たただの外部システム(例えば`sendmail`コマンド）の利用手段になりました。

### 商品とコードの組み合わせチェックに注目する
次は行数やインデントのせいかとても目立つ組み合わせチェックの部分に注目します。

ユーザのチェックや正常時の後続処理等と絡み合っていますが、ここは思い切って切り出してみるために作る処理の型から考えます。

```Haskell
checkCombination :: Item -> Maybe Option -> ???
```

戻りはどうすれば良いでしょうか。
`String`でも実装できそうですが、やはり専用の型を作ってみたいと思います。

```Haskell
data InvalidReason = PersonalComputerAndReplacement | KeyboardAndBackup deriving (Show, Eq)
```

そして不正ではない場合もあるので、ここは`Maybe`を用いてみます。
この条件判断は外部の値や環境に依存しない、仕様から生まれた処理なので、当然関数です。

```Haskell
checkCombination :: Item -> Maybe Option -> Maybe InvalidReason
```

Haskellらしく`case of`を用いてみました。

```Haskell
checkCombination :: Item -> Maybe Option -> Maybe InvalidReason
checkCombination item option = case (item, option) of
    (PersonalComputer, Just Replacement) -> Just PersonalComputerAndReplacement
    (Keyboard,         Just Backup)      -> Just KeyboardAndBackup
    _                                    -> Nothing
```

`apply`アクションにどう組み込むかはまだわかりませんが、適切な関数を作ることを優先してこう実装してみました。
この`checkCombination`としての分離により、商品やオプションの追加が`apply`に影響しなくなりました。

それはつまり仕様変更が関数の改修だけで対応が出来るということです。
仕様変更がシステムロジックには一切の影響を与えないと言う事は、業務ロジックが関数にうまく分離できているということです。

### applyの戻りの型はどうするのか
最後に、放置していた`apply`に注目します。

```Haskell
apply :: UserId -> Item -> Maybe Option -> IO String
```

ライセンスも不正理由も`String`だったため上手く動作していましたが、`LicenseKey`と`InvalidReason`という専用クラスに別れてしまいました。
当然共通の`Interface`を用意すれば動きそうではありますが、そもそもこの2つは全く別の概念なので都合良く`String`、もしくは適当な`Interface`に突っ込んでしまうのは不適切です。

ここは`Either`というものを用いてみたいと思います。

#### Either
`Maybe`と同じように、具体的な型と組み合わせて新たな型を表現する感じです。
`Either`は`Maybe`とは異なり、その具体的な型を2つ用います。

一般に`Either Left Right`と言い、`Left`には失敗時の型を、`Right`には成功時の型を書き、どちらか片方を詰めて使います。
（`Right`と`正しい`がかかっているそうです。`Either L R`はHaskellに限らず他の言語でも同じです）

例えば以下の様に使います。

```Haskell
half :: Int -> Either String Int  -- 失敗時は文字列（でメッセージ）、成功時は演算結果を返す
half x = case odd x of
    True -> Left "not even!"      -- Left String で失敗を表現
    False -> Right (div x 2)      -- Right Int で成功を表現
```

```Haskell
print (half 3) -- Left "not even!"
print (half 4) -- Right 2
```

`String`か`Int`が返る訳ではなく、`half 3`と`half 4`の結果のどちらもが`Either String Int`型なので、型の不整合は起きません。

#### applyの戻りをEitherにする
さっそく書いてみます。

```Haskell
apply :: UserId -> Item -> Maybe Option -> IO (Either InvalidReason LicenseKey)
```

少し長いですが、副作用を内包することと、正常時は`LicenseKey`を、失敗時は`InvalidReason`を返すことが型だけでわかるようになりました。
本文の実装は`checkCombination`と合う様によしなに実装し直します。

### 上記を踏まえて書き直す
最終的には以下の様になりました。

```Haskell
import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data UserId = UserId { value :: String } deriving (Show, Eq)

data LicenseKey = LicenseKey { key :: String } deriving Show

data InvalidReason = NoUser | PersonalComputerAndReplacement | KeyboardAndBackup deriving (Show, Eq)

data MailTitle = MailTitle { title :: String } deriving Show

isExist :: UserId -> IO Bool
isExist userId = return True

checkCombination :: Item -> Maybe Option -> Maybe InvalidReason
checkCombination item option = case (item, option) of
    (PersonalComputer, Just Replacement) -> Just PersonalComputerAndReplacement
    (Keyboard,         Just Backup)      -> Just KeyboardAndBackup
    _                                    -> Nothing

save :: UserId -> Item -> Maybe Option -> IO LicenseKey
save userId item option = return (LicenseKey "license-key-123")

sendMail :: MailTitle -> IO ()
sendMail title = do
    print title

mailTitle :: UserId -> Item -> Maybe Option -> MailTitle
mailTitle userId item option = MailTitle ((show userId) ++ " " ++ show item ++ " " ++ maybe "" show option)

apply :: UserId -> Item -> Maybe Option -> IO (Either InvalidReason LicenseKey)
apply userId item option = do
    b <- isExist userId

    -- ユーザが存在しなければ NoUser, 存在すれば組み合わせチェック次第
    let invalidReason = if b then (checkCombination item option) else Just NoUser

    case invalidReason of
        (Just reason) -> do                          -- 不正理由がある場合は
            return (Left reason)                     -- Left 理由
        Nothing -> do                                -- 不正理由がない場合は
            license <- save userId item option       -- 後続処理を行い
            sendMail (mailTitle userId item option)
            return (Right license)                   -- Right ライセンス

main = do
    let userId = UserId "user-id-123"

    r1 <- apply userId PersonalComputer Nothing
    print r1

    r2 <- apply userId PersonalComputer (Just Backup)
    print r2

    r3 <- apply userId PersonalComputer (Just Replacement)
    print r3

    r4 <- apply userId Keyboard (Just Backup)
    print r4
```

単純な行数は増えましたが、何カ所かは適切に関数とアクションが切り分けられました。
また、型定義の部分だけ抜粋すると以下の様になります。

```Haskell
isExist :: UserId -> IO Bool

checkCombination :: Item -> Maybe Option -> Maybe InvalidReason

save :: UserId -> Item -> Maybe Option -> IO LicenseKey

sendMail :: MailTitle -> IO ()

mailTitle :: UserId -> Item -> Maybe Option -> MailTitle

apply :: UserId -> Item -> Maybe Option -> IO (Either InvalidReason LicenseKey)
```

何に基づき何を返すかとか、結果があったりなかったりする(`Maybe`)とか、成功時と失敗時で違う型を返したい(`Either`)とか、副作用がある(`IO`)とか、型からわかる情報が大分増えたと思います。

実装はひとまずここまでとします。

## 始めからHaskellならどうだったか
先述の「小規模な仕様をお題としてHaskellで実装している」ですが、これはドメイン層を最初に書いて、ドメイン層が書き上がるまで他の層を一切書きませんでした。
そして単体テストや`REPL`を用いてドメイン層の開発だけを行い、他の層を書くことなく実装を終わらせました。
（`REPL`も実はHaskellでドメイン層を書く際の非常に強力な利点です。単体テストや`REPL`についてはまた別の機会にしたいと思います。）

型だけ用意して関数の型定義までを行い、本文は所謂`return null;`の様な状態で関数定義だけを進めるというやりかたも出来ます。
これはチーム開発時に分担作業がしやすくなる等のメリットがあります。「設計はトップダウン、実装はボトムアップ」という考え方がピタリと合うと思いました。

いずれにせよHaskellであれば業務ロジックの中にシステムロジックを混ぜることは不可能であるし、
システムロジックの中で呼んでいる処理が関数であればドメイン層に切り出すべきだと言う事は自明であるので、
今回の様に「見直してみたら混じっていた」という状況がそもそも起きません。

純粋なドメイン層を作るという点に関しては極めて適した言語だと実感しました。

## なぜHaskellを選んだか
整理すると以下の様な理由になります。

+ 関数とアクションは定義が別であること
+ その関数とアクションがぴったり業務ロジックとシステムロジックに相当すると思ったこと
+ 参照透過性を保つために関数からはアクションが呼べないため、業務ロジックにシステムロジックが混入することは絶対にないこと
+ 型の表現力が豊富なこと

現在レイヤー設計について色々と考えていますが、その根底にある発想は「業務ロジックは関数である」ことです。
ドメイン層やサービス層等にシンプルかつ強力な制限事項を設けることで、Haskellであればある程度は適切なDDDが自然と行えることを検証中です。

また必ずしも業務をHaskellで行わなくとも、関数とアクションについての感覚は他の言語で実装する際にも役に立つと実感しています。

## 反省点
`isExist`と`save`、つまりDBアクセスに関連するところの型定義を見ると改善の余地がありそうです。
もうひとつは`apply`の中のコメントでの補足を必要としてしまっている`NoUser`の下りです。

### 参照系
参照系については今現在とても悩んでいるところですが、DBアクセスは参照する条件を詰めた型を渡し、レコードを適切な型にして`Maybe`か`List`で返すだけに留めるべきだと感じています。

例えば今回は主キー検索でしたが、「IDとステータスと申込日時をキーとして参照する」様な複雑な状況になれば話は別です。
ステータス判定も日時判定もまず大抵の場合は仕様起因です。つまり業務ロジックです。
それをひとつのアクションに押し込めてしまうのには大きな違和感を覚えます。

例えば以下の様にするべきでしょうか？

```Haskell
data XxxFindCond = XxxFindCond { userId :: UserId, status :: Status, appliedDate :: AppliedDate }

find :: XxxFindCond -> Maybe User
```

`XxxFindCond`は例えば「解約時における参照条件」とでも言う、仕様起因で存在するまとまりです。
この型の実装を見ることで「解約にはステータスと申込日時も参照条件に関連する」という仕様を知ることが出来ます。

これを`find :: UserId -> Maybe User`としてしまい、例えばSQLで`where status == 50 and date ...`とハードコーディングしてしまうと、業務ロジックがシステムロジックに完全に隠れてしまいます。

### 更新系
更新系は今回の例が悪かったのだと思いますが、保存ついでに`LicenseKey`を発行するのは不適切でした。

```Haskell
save :: UserId -> Item -> Maybe Option -> IO Xxx

allocate :: Xxx -> LicenseKey
```

の様に、保存した結果を用いて得られると言うことを関数で表現するべきだったと思います。
例えば`Item`も組み立てに必要であれば`allocate :: Xxx -> Item -> LicenseKey`となり、`save`で全て済ませてしまうより業務ロジックが見えやすくなります。

アクションからいかに業務ロジックを切り離すかは悩んでいる途中ですので、これ以上の詳細はいずれ別にまとめたいと思います。

### NoUserの下り
コメントが必要である以前に、明らかに仕様起因であるロジックがシステムロジック（`IO`を返す`apply`）の中に埋もれています。

ここは先述の通り、やはり`isExist`ではなく`find`で`Maybe User`を手に入れ、それも一緒に使って判断する関数を書くべきでした。

```Haskell
checkApplicable :: Maybe User -> Item -> Maybe Option -> Maybe InvalidReason
checkApplicable user item option = case user of
    (Just _) -> checkCombination item option -- checkCombination はそのまま使う
    Nothing  -> NoUser
```

```Haskell:apply
user <- find userId

let invalidReason = checkApplicable user item option -- if が消えた
```

これで「申込可能か」という処理は型を見るだけで「`Maybe User`, `Item`, `Maybe Option`で判断できる業務ロジック」である、と示すことが出来たはずでした。

`isExist`を作ったときの経験不足による判断ミスに引きずられた形になってしまいました。

## 今後
1年会社で見よう見まねでやりましたが、色々な思いがありずっとDDDというもの自体に対するモチベーションがありませんでした。
ですから実はここ2週間ほどで初めて「DDD始めた」という感覚になりました。

気になることは沢山あるのでもう少し考えるつもりです。
IdentityとEntityについて、DBアクセスの型定義について（反省点の部のこと）、レイヤー設計について、Aggregateについて、単体テストについて、ドメインモデルについて等々。

その際はまたまとめて見たいと思っていますが、根底にある考えは今回のHaskellを選んだ理由の部にあり、それを伝えてみようと思い長い記事になってしまいました。

何かの参考になれば幸い。
もしも指摘がもらえれば、参考にもモチベーションの向上にもなる。
2-3年して見返したら面白いかも知れないな。

なんて思い、長々とまとめてみました。

以上です。

## おまけ
気を抜いて楽な感じでいくつかおまけを

### 他の言語で副作用を気にする
例えばJavaでやりがちな以下のコード

```Java
public class Bar {
    private String key;
    private int n;
    private Status status;

    private String message;

    public Bar(String key, int n, Status status) {
        this.key = key;
        this.n = n;
        this.status = status;

        this.message = createMessage();
    }

    private String createMessage() {
        if (status == Status.OK) {
            return key + n;
        } else {
            return key;
        }
    }
}
```

こういう自身のフィールドに依存する処理は僕は好きじゃあない。OOPのべき論は知らんす。好き嫌いです。

```Java
    public Bar(String key, int n, Status status) {
        this.key = key;
        this.n = n;
        this.status = status;

        this.message = createMessage(key, n, status);
    }

    private static String createMessage(String key, int n, Status status) {
        if (status == Status.OK) {
            return key + n;
        } else {
            return key;
        }
    }
```

`statis`にして中で使う値は外から全て渡したい
`createMessage`が別のタイミングで再利用された場合に、（この例で言えば）自身のフィールドの値が変わっていない保証がないから
同じ`createMessage`でも、前後や内部を気にしないと同じ結果かわからないなんて、むしろ怖くて再利用したくなくなってしまう

他の処理結果を内包して使っていたり、利用順に注意が必要だったりすると安心できない、ので、僕は`statis`が好き

（ちなみに、`SpringFramework`の`Service`や`Repository`ってシングルトンだし、こういう`static`にしたくなるロジックも普段結構あるし、
　もしかしてこの`static`ってのが業務ロジックでシングルトンのやつがシステムロジックなんじゃね？
　というかじゃあむしろ状態排除そんなにしたいならOOPじゃあなくてもDDD出来るんじゃね？って思ったのが始まりの様なもの）

### 型の表現力
選んだ理由にて上げた表現力ですが、今回出てきていないことがいくつもあるので紹介します

#### List
`[a]`を使うだけです、簡単です

```Haskell
find :: UserName -> [User]
```

#### Tuple
当然あります
`(a, b)`を使うだけです、簡単です

```Haskell
authentication :: (UserId, Password) -> AuthResult
```

#### 関数渡し
当たり前すぎますがあります
`(a -> b)`を使うだけです

```Haskell
map :: (a -> b) -> [a] -> [b]
```

標準ライブラリの`map`。
`a`を`b`にする方法と`a`を複数与えると複数の`b`になる。
（`a`と`b`は何に読み替えても良い。Javaのジェネリクスの様な感じ。）

#### MaybeのTupleがListでEitherだしIO
パルスのファルシのルシがコクーンでパージみたいになってきたｗ

長いけどJavaよりずっと短いです
引数と戻りが格段に把握しやすい

```Haskell
findItems :: UserId -> IO (Either ErrorMessage [(Item, Maybe Option)])
```

ユーザの商品をあるかも知れないオプションとセットにしてリストで得る（副作用あり）、って一目でわかる

```Java
public Either<ErrorMessage, List<Tuple<Item, Optional<Option>>>> findItem(UserId userId) {
```

`List`と`Optional`を`import`して、`Tuple`と`Either`は自作するなり`javaslang`を使うなりして用意しないと... (´Д｀；)ハァ...

#### 型エイリアス
新しい型を作るのではなく、ラベルを付ける様にエイリアスを作れます

```Haskell
type Contracted = (Item, Maybe Option)

findItems :: UserId -> IO (Either ErrorMessage [Contracted])
```

もっとやってもおｋ

```Haskell
type Contracteds = [Contracted]

findItems :: UserId -> IO (Either ErrorMessage Contracteds)
```

すっきりした！
（Tupleを使うか型を作るかについてはまたいつか）

### 丸括弧を減らす
実はあえて`()`を使っていたけど、`$`という演算の優先度を下げる方法がある

これを使うと例えば

```Haskell:これが
sendMail (mailTitle userId item option)
```

```Haskell:こうなる
sendMail $ mailTitle userId item option
```

どちらも書かないと`sendMail`の第一引数が`mailTitle`と解釈されてしまうけど、
`mailTitle`以降を先に評価して、その結果を`sendMail`に渡したいってこと、よくあるよね

```Haskell:これが
return (Right license)
```

```Haskell:こうなったり
return $ Right license
```

```Haskel:これも
r3 <- apply userId PersonalComputer (Just Replacement)
```

```Haskel:こうなったりする
r3 <- apply userId PersonalComputer $ Just Replacement
```

一番右に閉じ括弧がある開き括弧だと思えばおｋ
これを使うと行末が`))))`みたいなことにならなくて済む

おまけは以上！ﾉｼ
