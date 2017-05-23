module Writer where

import Control.Monad.Writer

import Types

measure :: Temperature -> Writer [TemperatureLog] Temperature
measure temperature = writer (temperature, ["temperature: " ++ show temperature])


measureAt :: Temperature -> Time -> Writer [TemperatureLog] Temperature
measureAt temperature time = writer (temperature, ["temperature: " ++ show temperature ++ " at " ++ time])


{-

writerでWriterのインスタンスが作れる

:t writer
writer :: MonadWriter w m => (a, w) -> m a

:t measure 37.4
measure 37.4 :: Writer [TemperatureLog] Temperature


WriterはrunWriterという関数の属性を持っている

newtype Writer w a = Writer { runWriter :: (a,w) } 

:t runWriter
runWriter :: Writer w a -> (a, w)

一見ん？だけどただのゲッター

writer (a, w)で渡した値をrunWriterという属性名で保持している

runWriter $ measure 37.4
(37.4,["temperature: 37.4"])


data Mail = Mail { body :: String } deriving Show
Mail "hello"
Mail {body = "hello"}
body $ Mail "hello"
"hello"



これが不思議に見えた
measureは値しか受け取っていないのに、なぜ"追記"出来るんだろう

runWriter $ measure 37.4 >>= measure
(37.4,["temperature: 37.4","temperature: 37.4"])


bind時に2つの結果を結合してる

instance (Monoid w) => Monad (Writer w) where
    return x = Writer (x, mempty)
    (Writer (x, v)) >>= f = let (Writer (y, v')) = f x
                             in Writer (y, v `mappend` v')

それならdo記法で結果が結合されるのもわかる


ApplicativeFunctorでも書ける
実装が見つけられなかったけど、Monadと同じできっと値の方だけ計算に使って出来たWriterを結合してる感じなんだと思う
-}
