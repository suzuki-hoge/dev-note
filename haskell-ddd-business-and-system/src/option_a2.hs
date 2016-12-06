import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data UserId = UserId { value :: String } deriving Show

sendMail :: UserId -> Item -> Maybe Option -> IO ()
sendMail userId item option = do
    putStr "メールを送信しました 件名: "
    putStrLn ((show userId) ++ " " ++ show item ++ " " ++ fromMaybe "" (fmap show option))

main = do
    sendMail (UserId "user-id-123") PersonalComputer Nothing
