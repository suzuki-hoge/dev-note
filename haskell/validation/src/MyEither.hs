data MyEither a b = MyLeft a | MyRight b deriving Show

instance Functor (MyEither a) where
    fmap f (MyRight x) = MyRight $ f x
    fmap f (MyLeft x) = MyLeft x

instance Applicative (MyEither a) where
    pure = MyRight
    (MyLeft x) <*> _ = MyLeft x
    (MyRight f) <*> something = fmap f something

main = do
    let r1 = MyRight 2 :: MyEither String Int
    let r2 = MyRight 5 :: MyEither String Int
    let l1 = MyLeft "error1" :: MyEither String Int
    let l2 = MyLeft "error2" :: MyEither String Int

    print r1 -- MyRight 2
    print l1 -- MyLeft "error1"

    print $ fmap (+2) r1 -- MyRight 4
    print $ fmap (+2) l1 -- MyLeft "error1"

    print $ (+) <$> r1 <*> r2 -- MyRight 7
    print $ (+) <$> r1 <*> l1 -- MyLeft "error1"
    print $ (+) <$> l1 <*> l2 -- MyLeft "error1"
    print $ (+) <$> l2 <*> l1 -- MyLeft "error2"
