{-
普通の値を受けて文脈で返す関数に文脈の値を渡したい

(>>=) :: (Monad m) => m a -> (a -> m b) -> m b
 -}

append :: Int -> Maybe Int
append x = Just (x + 1)

applyMaybe :: Maybe a -> (a -> Maybe b) -> Maybe b
applyMaybe Nothing f = Nothing
applyMaybe (Just x) f = f x

{-
class Monad m where
    return :: a -> m a

    (>>=) :: m a -> (a -> m b) -> m b

    (>>) :: m a -> m b -> m b
    x >> y = x >>= \_ -> y

    fail :: String -> m a
    fail msg = error msg

return : pureみたいなもん
bind
まずデフォルト実装を上書かない
自前では呼ばない

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

instance Monad Opt where
    return = Some
    None >>= f = None
    Some x >>= f = f x
    fail _ = None


optHalf :: Int -> Opt Int
optHalf x = case even x of
    True -> Some $ x `div` 2
    _    -> None

up :: Int -> Int
up x = x + 1

down :: Int -> Int
down x = x - 1

(-:) x f = f x

up' :: Int -> Opt Int
up' x
    | x < 3     = Some $ up x
    | otherwise = None
    

down' :: Int -> Opt Int
down' x = Some $ down x

main = do
    print $ append 5

    print $ (Just 5) `applyMaybe` append

    print $ (return "Foo" :: Opt String)
    print $ Some 5 >>= (\x -> Some $ x + 1)
    print $ Some 5 >>= (\x -> return $ x + 1)
--     print $ Some 5 >>= (\x -> return None) -- Some Noneになってる

    let f x = None :: Opt Int
    print $ f 5
    print $ Some 5 >>= f

    print $ fmap f (Some 5) -- a -> b だからネストする

    print $  Some 40 >>= optHalf
    print $  Some 40 >>= optHalf >>= optHalf

    print $  Some 5 >>= optHalf >>= optHalf

    print $ 1 -: up
    print $ 1 -: up -: up -: down -: up -: up -: down

    print $ Some 1 >>= up' >>= up' >>= down' >>= up' >>= up' >>= down'
    print $ return 1 >>= up' >>= up' >>= down' >>= up' >>= up' >>= down'

-- Functor: 関数で移せる
-- ApplicativeFunctor: 普通の関数を複数の値に適用したり、普通の値をデフォルトの文脈に入れたり
-- Monad: 文脈の中の値を普通の関数に渡す
