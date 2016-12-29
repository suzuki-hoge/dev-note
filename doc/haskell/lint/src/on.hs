import Data.Function

data Card = Card { value :: Int, label :: String } deriving Show

-- sameValue x y = value x == value y
sameValue = (==) `on` value

main = do
    let card1 = Card 1 "foo"
    let card2 = Card 1 "bar"

    print $ (\x y -> value x == value y) card1 card2
    print $ sameValue card1 card2

{-
Found:
\x y -> cardNumber x == cardNumber y
Why not:
(==) `Data.Function.on` cardNumber
-}
