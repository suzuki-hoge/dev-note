data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data UserId = UserId { value :: String } deriving (Show, Eq)

data LicenseKey = LicenseKey { key :: String } deriving Show

data InvalidReason = NoUser | PersonalComputerAndReplacement | KeyboardAndBackup deriving (Show, Eq)

isExist :: UserId -> IO Bool
isExist userId = return True

checkCombination :: Item -> Option -> Maybe InvalidReason
checkCombination item option = case (item, option) of
    (PersonalComputer, Replacement) -> Just PersonalComputerAndReplacement
    (Keyboard, Backup) -> Just KeyboardAndBackup
    _ -> Nothing

save :: UserId -> Item -> Option -> IO LicenseKey
save userId item option = return (LicenseKey "license-key-123")

sendMail :: UserId -> Item -> Option -> IO ()
sendMail userId item option = do
    putStr "メールを送信しました 件名: "
    putStrLn (mailTitle userId item option)

mailTitle :: UserId -> Item -> Option -> String
mailTitle userId item option = (show userId) ++ " " ++ show item ++ " " ++ fromMaybe "" (fmap show option)

apply :: UserId -> Item -> Option -> IO (Either InvalidReason LicenseKey)
apply userId item option = do
    b <- isExist userId

    let invalidReason = if b then (checkCombination item option) else Just NoUser

    case invalidReason of
        (Just reason) -> return (Left reason)
        Nothing -> do
            license <- save userId item option
            sendMail userId item option
            return (Right license)

main = do
    let userId = UserId "user-id-123"

    r1 <- apply userId PersonalComputer Backup
    print r1

    r2 <- apply userId PersonalComputer Replacement
    print r2

    r3 <- apply userId Keyboard Backup
    print r3
