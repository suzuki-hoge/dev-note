inc :: Int -> Either String Int
inc x
    | x < 2     = Right $ x + 1
    | otherwise = Left "too big"

dec :: Int -> Either String Int
dec x
    | 0 < x     = Right $ x - 1
    | otherwise = Left "too small"

main = do
    print $ return 0 >>= inc
    print $ return 0 >>= inc >>= inc
    print $ return 0 >>= inc >>= inc >>= inc

    print $ return 0 >>= inc >>= dec >>= dec

    print $ return 0 >>= inc >>= dec >>= dec >>= inc >>= inc
