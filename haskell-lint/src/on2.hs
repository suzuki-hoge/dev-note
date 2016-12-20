import Data.List

main = do
    print $ groupBy (\x y -> odd x == odd y) [1, 3, 2, 4, 2, 4, 1, 3, 5, 2, 8]
