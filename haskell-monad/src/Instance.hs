data Opt a = None | Some a

instance (Show a) => Show (Opt a) where
    show None = "None"
    show (Some a) = "Some: " ++ show a

data User = User { name :: String } deriving Show

data ItemId = ItemId String deriving Show
data Item = Item ItemId deriving Show

main = do
    print $ User "John"

    print $ ItemId "item01"
    print $ Item $ ItemId "item01"

    print $ Some 5
