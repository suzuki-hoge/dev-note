import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data UserId = UserId { value :: String } deriving (Show, Eq)

sendMail :: UserId -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStr "メールを送信しました 件名: "
    putStrLn (mailTitle userId item option)

mailTitle :: UserId -> Item -> Maybe Option -> String
mailTitle userId item option = (show userId) ++ " " ++ show item ++ " " ++ fromMaybe "" (fmap show option)

main = do
    let userId = UserId "user-id-123"
    sendMail userId Keyboard (Just Replacement)
