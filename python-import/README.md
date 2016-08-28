Pythonのimportについてまとめる

何度もハマるので頭に刻み込む様に調べて習得するよ

# 前提
## 検証環境
+ 実行は全て`tree`コマンドを実行したパスと同パスでREPLを起動して行っている
+ Pythonは2.7.5

## パッケージとは
+ Pythonでは`__init__.py`を含むディレクトリをパッケージと言う
+ ただのディレクトリでは再帰的にモジュールを検索しないため、基本的には`__init__.py`が必要

## 読み込み時に検索する範囲
1. 実行ディレクトリと同ディレクトリ
+ カレントディレクトリ
+ 環境変数「PYTHONPATH」に列挙したディレクトリ
+ sys.pathに含むディレクトリ

`sys.path`は絶対パスの文字列リストであり、`import sys; print sys.path` 等の方法で確認できる

# 実例
## 同ディレクトリのメソッドをimportする
```
$ tree --charset=C
.
`-- greeting.py
```

```Python:greeting.py
def daytime():
    print 'hey'
```

```Python:REPL
>>> import greeting

>>> greeting.daytime() # 呼ぶ
hey
```

### importしたものを理解する
```Python:REPL
>>> import greeting

>>> print type(greeting)         # importしたgreetingはmoduleというオブジェクトらしい
<type 'module'>

>>> print dir(greeting)          # daytime属性を持っているのがわかる（一部略）
['__builtins__', ..., 'daytime']

>>> greeting.daytime()           # 呼ぶ時はこう
hey

>>> print type(greeting.daytime) # 呼んだものはfunctionというオブジェクトらしい
<type 'function'>
```

### fromを使って書く
```Python:REPL
>>> from greeting import daytime

>>> daytime()                    # 呼ぶ
hey
```

### from-importしたものを理解する
`from`を使って`import`したものも理解しよう

```Python:REPL
>>> from greeting import daytime

>>> print type(daytime)          # こうしてimportしたdaytimeはfunctionというオブジェクトらしい
<type 'function'>

>>> print dir(daytime)           # 特に自分で定義した属性は無い（一部略）
['__call__', ..., 'func_name']

>>> daytime()                    # 呼ぶ時はこう
hey

>>> print type(daytime)          # 呼んだものとimportしたものは同じ
<type 'function'>
```

### 整理
この2つの例を見ると、以下の2つは同じものを指していることが理解できる

+ `from`を用いていない方の例に出てきた`greeting`が持っている`daytime`属性
+ `from`を用いた方の例の`daytime`

```Python:REPL
>>> import greeting

>>> print type(greeting.daytime)
<type 'function'>


>>> from greeting import daytime

>>> print type(daytime)
<type 'function'>
```

どちらも`function`オブジェクトだから、括弧を付ければ呼べるというわけだ

```Python:REPL
>>> import greeting

>>> greeting.daytime()
hey


>>> from greeting import daytime

>>> daytime()
hey
```

## 同ディレクトリにあるパッケージのメソッドをインポートする
`module`オブジェクトと`function`オブジェクトを知ったところで、別パッケージのimportを試してみる

```
$ tree --charset=C
.
`-- subdir
    `-- greeting.py
```

```Python:REPL
>>> import subdir
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ImportError: No module named subdir
```

冒頭で述べた通り、`__init__.py`を置かないと`subdir`はパッケージとして認識されない

```
$ touch subdir/__init__.py
```

もう一度

```Python:REPL
>>> import subdir

>>> print dir(subdir)             # が、greeting属性がない
['__builtins__', ..., '__path__']
```

どうやらパッケージをインポートしても、内包するファイルがすべて勝手に使える訳ではない様だ
`greeting`をインポートしたい場合は、 **subdirのgreeting** をインポートする必要がある

```Python:REPL
>>> import subdir.greeting

>>> subdir.greeting.daytime()
hey
```

### importしたものを理解する
少し前置きが長かったけど、要はやったのは`import subdir.greeting`だけだ
今度はこれを理解したいと思う

```Python:REPL
>>> import subdir.greeting

>>> print type(subdir.greeting)         # やはりimportしたものはmoduleオブジェクト
<type 'module'>

>>> print dir(subdir.greeting)          # daytime属性がある
['__builtins__', ..., 'daytime']

>>> subdir.greeting.daytime()           # だから、こう呼べる
hey

>>> print type(subdir.greeting.daytime) # そして、やはり呼んだものはfunctionオブジェクトだ
<type 'function'>
```

### fromを使って書く
先ほどの`import greeting`を`from greeting import daytime`と書けたことを考えると、
fromには`module`オブジェクトを書くと考えれば良さそう
なので以下の書き方ができる

```Python:REPL
>>> from subdir import greeting  # from部分にmoduleを書く

>>> greeting.daytime()           # こう呼べる
hey
```

また、fromには`module`を階層構造に則って連結して書くことが出来る

```Python:REPL
>>> from subdir.greeting import daytime  # from部分にmoduleを連結して書く

>>> daytime()                            # こう呼べる
hey
```

### from-importしたものを理解する
もうなんとなくわかる気もするけど、この例も理解したいと思う

```Python:REPL
>>> from subdir import greeting

>>> print type(greeting)          # importしたものはmoduleオブジェクト
<type 'module'>

>>> print dir(greeting)           # daytime属性を持っているので
['__builtins__', ..., 'daytime']

>>> greeting.daytime()            # こう呼べる
hey

>>> print type(greeting.daytime)  # やはり呼んだものはfunctionオブジェクトだ
<type 'function'>
```

```Python:REPL
>>> from subdir.greeting import daytime

>>> print type(daytime)                  # こちらはimportしたものはfunctionオブジェクト
<type 'function'>

>>> daytime()                            # こう呼べる
hey

>>> print type(daytime)                  # 呼んだものとimportしたものは同じ
<type 'function'>
```

### 整理
いままで5つくらいの例を試したけど、実行したオブジェクトは全て`function`のオブジェクトだ
`import`したものが`module`であれば、持っている`function`属性を
`import`したものが`function`であれば、その`function`オブジェクトを呼び出すことが出来る

だから、下の3例は全て同じものを指している

```Python:REPL
>>> import subdir.greeting
>>> print type(subdir.greeting.daytime)
<type 'function'>

>>> from subdir import greeting
>>> print type(greeting.daytime)
<type 'function'>

>>> from subdir.greeting import daytime
>>> print type(daytime)
<type 'function'>
```

## 同ディレクトリのクラスをimportする
いままでの例はメソッドだったが、クラスだとどうなるかも理解したい

```
$ tree --charset=C
.
`-- person.py
```

```Python:person.py
class Person():
    def daytime(self):
        print 'hey'
```

```Python:REPL
>>> import person

>>> person.Person().daytime()
hey
```

### importしたものを理解する
ここまでが理解できていれば簡単だった

```Python:REPL
>>> import person

>>> print type(person)                 # おなじみのmoduleオブジェクト
<type 'module'>

>>> print dir(person)                  # Person属性がある
['Person', ..., '__package__']

>>> print type(person.Person)          # メソッドと違いclassobjというオブジェクトになるらしい
<type 'classobj'>

>>> print dir(person.Person)           # daytime属性がある
['__doc__', ..., 'daytime']

>>> person.Person().daytime()          # クラスなのでインスタンス生成をしてから呼び出す
hey

>>> print type(person.Person.daytime)  # functionとは違いinstancemethodと言うらしい（staticmethodとかはクラスの話になるので省略）
<type 'instancemethod'>
```

### fromを使って書く
```Python:REPL
>>> from person import Person

>>> Person().daytime()
hey
```

ファイル名とクラス名が同じ場合は多いと思う
`from xxx Import Xxx`というインポート文が頻出するのはこういうことだったんだ

### from-importしたものを理解する
もうわかった気がするけど、一応

```Python:REPL
>>> from person import Person

>>> print type(Person)          # やはりclassobjオブジェクトで
<type 'classobj'>

>>> print type(Person.daytime)  # 持っているdaytime属性がinstancemethodだから
<type 'instancemethod'>

>>> Person().daytime()          # こう呼べる
hey
```
### 整理
クラスの場合もメソッドの場合が理解できていれば大差ない様だ
`function`ではなく`classobj`を扱えば良いだけみたいだ

# まとめ
## importするものが何で、使うものが何か
### メソッド
```Python:REPL
>>> import greeting              # ファイル名をimportする

>>> print type(greeting)         # importしたものはmodule
<type 'module'>

>>> print type(greeting.daytime) # 実際に使えるメソッドはfunction
<type 'function'>
```

### クラス
```Python:REPL
>>> import person                # ファイル名をimportする

>>> print type(person)           # importしたものはmodule
<type 'module'>

>>> print type(person.Person)    # 実際に使えるクラスはclassobj
<type 'classobj'>
```

## できること、できないこと
### fromを使わない場合はimportに書けるのはmoduleのみ
```Python:REPL
>>> import greeting.daytime
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ImportError: No module named daytime    # daytimeはmoduleではなくfunctionのため、確かにNo module

>>> import person.Person
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ImportError: No module named Person     # Personもmoduleではなくclassobjのため、確かにNo module
```

fromなしimportの要点は2つ！

+ import対象が`module`であること
+ 使う時は`function`か`classobj`であること

### fromを使う場合はimportにはなんでも書ける
```Python:REPL
>>> from greeting import daytime         # functionをインポート

>>> from person import Person            # classobjをインポート

>>> from subdir import greeting          # moduleをインポート

>>> from subdir.greeting import daytime  # functionをインポート
```

### ただし、fromを使う場合はimportに.を使えない
```Python:REPL
>>> import subdir.greeting               # importだけなら.が使えるが

>>> from subdir import greeting.daytime  # fromがある場合はimportに.を使えない
  File "<stdin>", line 1
    from subdir import greeting.daytime
```

# おまけ
ここから下は検証不足だったりPythonらしさ不足だったりする可能性が高いです

## fromを使うか使わないか
pythonはとてもよく書くのだけど、独学だし仕事で使ったことが無いので慣例の様なものがわからない
判断材料としては以下の様なものがあるのかな？
少なくともプロジェクト単位では統一するべきだと思うけど、どうすべきなのかはいまいちわからない...

### fromなしのメリット
+ いちいちimport文に追記をしなくてもmath.tan等も使える
+ 万が一sinやcosという同名変数があってもぶつからない
+ いろいろなモジュールをインポートした場合に関係がわかりやすい

```Python:REPL
>>> import math

>>> print math.sin(0)
0.0

>>> print math.cos(0)
1.0
```

### fromありのメリット
+ 短い
+ モジュールの名前やパッケージ構成が変わった場合の修正がfromだけで良い

```Python:REPL
>>> from math import sin,cos

>>> print sin(0)
0.0

>>> print cos(0)
1.0
```

### fromによるデメリット
```Python:REPL
>>> from os.path import join
>>> from random import shuffle

>>> join('root', 'sub')  # joinってなんのモジュールのメソッド？リスト系？パス系？
>>> shuffle(range(100))
>>> abspath('current')   # abspathはimportに追記しないと使えない
```

## from xxx import *
```Python:greeting.py
def morning():
    print 'hello'

def daytime():
    print 'hey'

def evening():
    print 'good night'
```

以下の様にやると全ての`function`を読み込むことが出来る

```Python:REPL
>>> from greeting import *

>>> print dir()
['__builtins__', ..., 'daytime', 'evening', 'morning']
```

が、モジュール側の改修により、いつの間にかhelloもインポートする様になってしまっていて、
ローカル変数のhelloが上書きされたことにより、改修していないのにバグった...
なんてことにならない様に、`from xxx import *`は避けた方が良いと思う

ちなみに、fromを用いない場合は出来ない
import出来るのは`module`だけだと理解していれば間違えないと思う

```Python:REPL
>>> import daytimeing.*
  File "<stdin>", line 1
    import daytimeing.*
                    ^
SyntaxError: invalid syntax
```

## 上にあるモジュールをインポートする
### 実行パスよりは上にならない場合
```
$ tree --charset=C         # REPLはここで起動する
.
`-- lib
    |-- __init__.py
    |-- commons.py         <-.
    `-- util                 |
        |-- __init__.py      |
        `-- listutils.py   --'
```

```Python:lib/commons.py
def commons():
    print 'commons'
```

```Python:lib/util/listutils.py
from .. import commons

def listutils():
    commons.commons()
    print 'list utils'
```

```Python:REPL
>>> import lib.util.listutils

>>> lib.util.listutils.listutils()
commons
list utils
```

`from`に`..`と書くことで、そのモジュールから見た上への相対パスを書くことが出来る
**ただし、実行したパスより上を指定することは出来ない** 次の例で確かめる

### 実行パスより上になる場合
```
$ tree --charset=C ..
..
|-- __init__.py
|-- lib.py             <---.
`-- main               ----'  # REPLはここで起動する 
```

```Python:../lib.py
def lib():
    print 'lib'
```

```Python:REPL
>>> from .. import lib
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ValueError: Attempted relative import in non-package
```

実行パスより上になる場合は`from .. import xxx`は出来ない様だ
厳密に言うと、`sys.path`より上はだめってことだと思う
だから、どうしてもインポートしたければ`sys.path`を追加すれば良い

```Python:REPL
>>> import sys

>>> sys.path.append('..')                             # sys.pathを追加する

>>> from .. import lib                                # from ..が出来る様になる訳ではない
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ValueError: Attempted relative import in non-package

>>> import lib                                        # 出来る様になるのはimport lib

>>> lib.lib()
lib
```

sys.path（とか）以下のパッケージを検索対象とする
ということが理解できていれば大丈夫だと思う

ただ、`sys.path`を追加して無理矢理ほかのモジュールをインポートしたりすると
インポートされる側が把握しきれなくなったりするし、
なによりパッケージ構成としておかしいと思うので個人的にはやるべきではないと強く思う

# おしまい
なんかすっごい行数になってしまった！
何日も隙を見つけてちまちま書いていたので、全体的な統一感が無い気もするけど、そんなことは良い

`type()`と`dir()`を確認しながら理解するというのはとても良かったと思う
もう`import`ではまったりはしないはず...！

PyCharmとか使うとどうなるのかは知らんす
けど、いつか試してみたい
