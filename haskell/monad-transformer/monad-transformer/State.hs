module State where

import Control.Monad.State

import Types


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

{-
runState haveACold 

<interactive>:44:1: error:
    • No instance for (Show (Health -> (Message, Health)))
        arising from a use of ‘print’
        (maybe you haven't applied a function to enough arguments?)
    • In a stmt of an interactive GHCi command: print it

Writeモナドと違ってshow出来ない

:t state
state :: MonadState s m => (s -> (a, s)) -> m a

一引数関数を渡すとStateモナドが出来る

Stateモナドは保持している属性が値では無く関数（不適切だけど便宜上）だからshow出来ない

runStateはrunWriteと同じ

newtype State s a = State { runState :: s -> (a, s) }

:t runState
runState :: State s a -> s -> (a, s)


つまり、runState haveAColdはs -> (a, s)を取り出しただけだからshow出来ない
手に入れた一引数関数に引数を渡す必要がある

runState haveACold Good 
("oops...",Bad)

runWriterと同じく、runしたらモナドは外れている

+ 条件分岐も無く一律で強制的に遷移させる例
+ 引数次第で遷移先が変わる例
+ 状態次第で遷移先が変わる例

型も見ないでただいきなりコピペだけしようとすると、

littleCold :: State Health Message
littleCold = state f
    where
        f :: Health -> (Message, Health)
        f Good = ("do not mind!", Good)
        f _    = ("oops... have again...", Bad)

引数の数があわない（様に見える）ので混乱する
littleColdに引数はないのに、fの最初の引数Healthはどこから手に入ったんだろうって思っていた
実はまだ手に入っていない

Stateモナドを作るlittleColdの様な関数は、その関数自体で状態を変えているのでは無く、
状態の換え型を定義しているに過ぎない

それに後から今の状態を与えると、定義に則って新しい状態を返してくれる

そんなイメージ

Health自体を保持していてあーだこーだ言いながらそれを書き換えていくイメージだったけど、
遷移させるルールを保持しているイメージ

 -}
