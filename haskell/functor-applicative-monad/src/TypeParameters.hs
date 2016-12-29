module TypeParameter where

data Opt a = None | Some a

-- Opt は型引数 a をとる型コンストラクタ
-- Opt という型の値は存在せず、Opt String の様になって初めて何らかの値となる

-- このままだとprintできない

-- data Opt a = None | Some a deriving Show では出力の仕方がわからない

instance (Show a) => Show (Opt a) where -- Show Opt ではない
    show None = "None"
    show (Some a) = "Some: " ++ show a -- show a にしないといけない

main = do
    let none = None :: Opt Int
    let some = Some 5 :: Opt Int
    print none
    print some

--     print None これだと Opt a の a が show かわからないからか
    print $ Some 5
