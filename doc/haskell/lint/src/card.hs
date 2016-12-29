import Data.List
import Data.Function

data Card = Card Int deriving (Show, Eq, Ord)

cardNumber :: Card -> Int
cardNumber (Card n) = n

main = do
    let cards = [Card 5, Card 3, Card 4, Card 4, Card 3, Card 3]

    print $ filter ((==2).length) $ groupBy (\x y -> cardNumber x == cardNumber y) cards
    print $ filter ((==2).length) $ groupBy ((==) `on` cardNumber) cards
