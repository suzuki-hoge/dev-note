data Opt a = None | Some a

instance (Show a) => Show (Opt a) where
    show None = "None"
    show (Some a) = "Some: " ++ show a

-- fmap :: (a -> b) -> f a -> f b
-- f は型引数のなにか

-- map :: (a -> b) -> a -> b
-- [a] -> [] a で、Opt a と同じ

{-
ghci> map (+2) [1, 2, 3]
[3,4,5]
ghci> fmap (+2) [1, 2, 3]
[3,4,5]
-}

-- instance Functor [] where
-- fmap = map

instance Functor Opt where
    fmap f None = None
    fmap f (Some a) = Some $ f a

{-
(a -> b) -> f a -> f b を置換して読み替えると
(a -> b) -> Opt a -> Opt b になる

instance Functor (Opt a) where ってすると
(a -> b) -> Opt a a -> Opt a b になる, Optは2つとらない
-}

optHalf :: Int -> Opt Int
optHalf x = case even x of
    True -> Some $ half x
    _    -> None

half :: Int -> Int
half = (`div` 2)

main = do
    let some = optHalf 40
    print $ some

    print $ fmap optHalf some -- Some: Some: 10

    print $ fmap half some
    print $ fmap half (fmap half some)

    print $ half `fmap` some
    print $ half <$> some
    print $ half <$> (half <$> some)

    print $ fmap half (fmap half some)
    print $ fmap (half . half) some -- Functor則2

    -- Just 3 + Just 5 は？
    -- optHalfを次々は？
