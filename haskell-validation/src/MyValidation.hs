data MyValidation a = MyFailure [String] | MySuccess a deriving Show

instance Functor MyValidation where
    fmap f (MySuccess x) = MySuccess $ f x
    fmap f (MyFailure x) = MyFailure x

instance Applicative MyValidation where
    pure = MySuccess
    (MyFailure x) <*> (MyFailure y) = MyFailure $ x ++ y
    (MyFailure x) <*> (MySuccess y) = MyFailure x
    (MySuccess x) <*> (MyFailure y) = MyFailure y
    (MySuccess f) <*> (MySuccess y) = MySuccess $ f y

main = do
    let r1 = MySuccess 2 :: MyValidation Int
    let r2 = MySuccess 5 :: MyValidation Int
    let l1 = MyFailure ["error1"] :: MyValidation Int
    let l2 = MyFailure ["error2"] :: MyValidation Int

    print r1 -- MySuccess 2
    print l1 -- MyFailure ["error1"]

    print $ fmap (+2) r1 -- MySuccess 4
    print $ fmap (+2) l1 -- MyFailure ["error1"]

    print $ (+) <$> r1 <*> r2 -- MySuccess 7
    print $ (+) <$> r1 <*> l1 -- MyFailure ["error1"]
    print $ (+) <$> l1 <*> l2 -- MyFailure ["error1","error2"]
    print $ (+) <$> l2 <*> l1 -- MyFailure ["error2","error1"]
