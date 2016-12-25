data UserId = UserId String deriving Show
data User = User UserId deriving Show

find :: UserId -> IO (Maybe User)
find userId = return $ Nothing

isExist :: Maybe User -> Bool
isExist user = case user of
    Nothing -> False
    _       -> True

foo :: Either String Int
foo = Right 5

bar :: Either String String
bar = Right "!"

f :: Int -> String -> String
f n s = (show n) ++ s

main = do
    let userId = UserId "abc12345"
    print userId

    user <- find userId
    print user

    print $ f 5 "!"

    print $ f <$> foo <*> bar
