import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

apply :: String -> Item -> Maybe Option -> IO String
apply userId item option = do
    user <- findUser userId

    if user == ""
        then return "ユーザが見つかりません"
        else if item == PersonalComputer && option == Just Replacement
            then return "PCに交換オプションは付加出来ません"
            else if item == Keyboard && option == Just Backup
                then return "キーボードにバックアップオプションは付加出来ません"
                else do
                    license <- save userId item option
                    sendMail userId item option
                    return license

findUser :: String -> IO String
findUser userId = return "John"

save :: String -> Item -> Maybe Option -> IO String
save userId item option = return "license-key-123"

sendMail :: String -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStr "メールを送信しました 件名: "
    putStrLn (userId ++ " " ++ show item ++ " " ++ fromMaybe "" (fmap show option))

main = do
    r1 <- apply "user-id-123" PersonalComputer Nothing
    putStrLn r1

    r2 <- apply "user-id-123" PersonalComputer (Just Backup)
    putStrLn r2

    r3 <- apply "user-id-123" PersonalComputer (Just Replacement)
    putStrLn r3

    r4 <- apply "user-id-123" Keyboard (Just Backup)
    putStrLn r4
