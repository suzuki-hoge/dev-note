import Control.Applicative

-- Functorは1引数だった
-- 多引数で写すと関数が入った値となる

{-
ghci> :t fmap (+) (Just 5)
fmap (+) (Just 5) :: Num a => Maybe (a -> a)
-}

-- ApplicativeはまずFunctorである

{-
class (Functor f) => Applicative f where
    pure :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b

pure はデフォルトの文脈に入れる
箱 => 文脈

instance Applicative Mayve where
    pure = Just
    Nothing <*> _ Nothing
    (Just f) <*> something = fmap f something -- somethingはFunctorなので、NothingならfmapでNothingになる

デフォルトってのは Just のこと

ghci> let mf = fmap (+) (Just 5)
ghci> :t mf
mf :: Num a => Maybe (a -> a)
ghci> :t (<*>)
(<*>) :: Applicative f => f (a -> b) -> f a -> f b
ghci> mf <*> (Just 5)
Just 10
ghci> 

ghci> (+) <$> (Just 5) <*> (Just 5)
Just 10

-}

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
--     (Some f) <*> something = f <$> something

main = do
    let some = Some 40

    print $ Some (+3) <*> some
    print $ pure (+3) <*> some
    print $ fmap (+) (Some 3) <*> some
    print $ (+) <$> (Some 3) <*> some

    print $ pure (+) <*> (Some 3) <*> some

    -- (+) <$> は文脈の中に入ってくれているものとしてくれる

    let one = Some 1
    let two = Some 2

    print $ (+) <$> one <*> two
    print $ liftA2 (+) one two
    print $ liftA2 (+) one None
