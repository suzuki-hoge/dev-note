trimOdd :: [Int] -> [Int]
trimOdd xs = filter (\x -> even x) xs

main = do
    print $ trimOdd [1..10]
