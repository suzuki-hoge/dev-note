data Opt a = None | Some a

instance (Show a) => Show (Opt a) where
    show None = "None"
    show (Some a) = "Some: " ++ show a

instance Functor Opt where
    fmap f None = None
    fmap f (Some a) = Some $ f a

instance Applicative Opt where
    pure = Some
    None <*> _ = None
    (Some f) <*> something = fmap f something

instance Monad Opt where
    return = Some
    None >>= f = None
    Some x >>= f = f x
    fail _ = None

-- No instance for (Monad m4) arising from a use of ‘>>=’

inc :: (Monad m) => Int -> m Int
inc x
    | x < 2     = return $ x + 1
    | otherwise = fail "too big"

dec :: (Monad m) => Int -> m Int
dec x
    | 0 < x     = return $ x - 1
    | otherwise = fail "too small"
