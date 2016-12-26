foo :: Maybe Int
foo = do
    x <- Just 5
    y <- Just 2
    return $ x + y

bar :: Maybe Int
bar = do
    x <- Just 5
    y <- Nothing
    return $ x + y

-- return はIO専用だと思っていた

e :: Either String Int
e = do
    x <- Right 5
    Left "error"
    y <- Right 2
    return $ x + y

baz :: IO Int
baz = do
    print "hoge"
    return 5

poo :: Maybe Int
poo = do
    return 5

zak :: IO Int
zak = do
    print "hoge"
    print $ Just 5
    return 5

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

optHalf :: Int -> Opt Int
optHalf x = case even x of
    True -> Some $ x `div` 2
    _    -> None

pon :: Opt Int
pon = do
    x <- return 5
    return 5 >>= optHalf
    y <- return 6 >>= optHalf
    return $ x + y

main :: IO ()
main = do
    print 5

-- 今回は使うのが目的なので則はスキップ
-- たとえ話や絵より、型で見るのが一番理解が早い気がした

-- mainは IO () の文脈だから、Nothingを扱っても終わらない
