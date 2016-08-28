takewhileとdropwhileでパス加工

何かを探すなら`find`みたいなメソッドがあるし、`filter`みたいにも使えないし、
`takewhile`と`dropwhile`っていつ使うんだろうと思ってた

けど先日うまく(?)使えた気がしたので小ネタとしてぶん投げておくよ

### 長い前置き
#### こんなパスが文字列であって
```
data/output/user/contract.csv
```

#### 任意の部分が欲しい
`outputまで`の部分(baseとする)と`user`の部分(dirとする)とする

#### とりあえずこの実装で動いてた
```Groovy
def base = path.split('/')[0..1].join('/') // data/output
def dir = path.split('/')[2]               // user
```

#### ディレクトリ、もっと切りたくなっちゃった！
```
data/ver1.0/output/user/contract.csv
```

むむ...添え字ずらしたぜ...

```Groovy
def base = path.split('/')[0..2].join('/') // data/ver1.0/output
def dir = path.split('/')[3]               // user
```

#### ツールのテストコード書こうぜ！
テストで使うダミーデータはこれな！

```
test/data/ver1.0/output/user/contract.csv
```

i...if使えば良いんだろ...はは...

```Groovy
if (isTest) {
  def base = path.split('/')[0..3].join('/') // test/data/ver1.0/output
  def dir = path.split('/')[4]               // user

} else {
  def base = path.split('/')[0..2].join('/') // data/ver1.0/output
  def dir = path.split('/')[3]               // user
}
```

#### いくらなんでもこの実装はないね
添え字アクセスじゃあわかりづらいし、ディレクトリ構造の変化に全く耐えられてない
しかもフラグで添え字を変えるなんてサイテーだ！

### そこでtakewhile/dropwhileだ！
`.../output`までが欲しいならtakewhileで、
`outputの次`が欲しいならdropwhileで良かったんだ！

```Groovy
def base = path.split('/').takeWhile {it != 'output'}.join('/').concat('/output') // data/ver1.0/output
def dir = path.split('/').dropWhile {it != 'output'}[1]                           // user
```

これならある程度は柔軟に自動に対応できるね（ツール設計上の理由等で`output`以下の構成は変わらない場合だけど）
それにしても、実は`takewhile`は初めて書いてみたんだけど、`output`は含まないんだね...そこだけちょい残念かな...

### おまけ
#### Groovy
書きやすいね、例の通り
メソッドチェインは読みやすいし、無名関数書くのも楽でベネ

#### Python
```Python
path = 'data/ver1.0/output/user/contract.csv'

import itertools

taken_iter = itertools.takewhile(lambda x: x != 'output', path.split('/'))
print '/'.join(list(taken_iter)) + '/output' # data/ver1.0/output

dropped_iter = itertools.dropwhile(lambda x: x != 'output', path.split('/'))
print list(dropped_iter)[1]                  # user
```

Python好きだけど、ちょっと残念かな...
xxxwhileがimportしてメソッド呼び出しってのと、結果に`list()`や`join()`かけないといけないので
1行で書くと`....))))`になってしまう
無名関数もGroovyやScalaと比べるとやや読みづらく、全体的に何しているか流れがわかりづらい、無念！

#### Haskell
```Haskell
import Data.List
import Data.List.Split

main = do
    let path = "data/ver1.0/output/user/contract.csv"

    print $ (intercalate "/"  $ (takeWhile (/= "output") $ splitOn "/" path)) ++ "/output"
    print $ (dropWhile (/= "output") $ splitOn "/" path) !! 1
```

やはりやることが多いからか、`(...)`が多くなってしまう...
あと本題とは関係ないけど、`splitOn`がインストールしないと使えないってどうなの！
結構よく使うんだけど！

#### Haskell2
```Haskell
import Data.List
import Data.List.Split

main = do
    let path = "data/ver1.0/output/user/contract.csv"

    let reversed = reverse $ splitOn "/" path
    print $ intercalate "/" $ reverse $ dropWhile (/= "output") reversed
    print $ last $ takeWhile (/= "output") $ reversed
```

takeWhileだと肝心の`output`が結果に含まれないので、要素を逆順にしてみた
すっきりしたかな！

他にもPHPとか考えてみたけど目立った差分が出なさそうだったので省略、Javaは面倒そう（偏見）だから却下
色んな言語で書いてみると色んな関数を知れて良いね！

どうしていつもこんだけの小ネタで長くなってしまうのか...
でも、便利さを伝えるにはダサさからだよね！

あとね、「文字列のままのパス」を「output」で分割すれば良いとか言う意見はなしね！
