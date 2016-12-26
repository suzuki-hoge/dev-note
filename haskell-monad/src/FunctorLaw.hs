-- id で写した場合、値が変わってはいけない

data Log a = Log a

instance (Show a) => Show (Log a) where
    show (Log a) = show a

instance Functor Log where
    -- fmap f (Log a) = Log $ f a 正しい
    fmap f (Log a) = Log $ ("log: " ++) a

main = do
    print $ fmap id (Just 5) -- Just 5

    let log = Log "some log line"
    print $ fmap (++"!") log
