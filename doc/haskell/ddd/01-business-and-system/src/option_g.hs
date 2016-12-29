import Data.Maybe

data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data UserId = UserId { value :: String } deriving (Show, Eq)

data LicenseKey = LicenseKey { key :: String } deriving Show

data InvalidReason = NoUser | PersonalComputerAndReplacement | KeyboardAndBackup deriving (Show, Eq)

data MailTitle = MailTitle { title :: String } deriving Show

isExist :: UserId -> IO Bool
isExist userId = return True

checkCombination :: Item -> Maybe Option -> Maybe InvalidReason
checkCombination item option = case (item, option) of
    (PersonalComputer, Just Replacement) -> Just PersonalComputerAndReplacement
    (Keyboard,         Just Backup)      -> Just KeyboardAndBackup
    _                                    -> Nothing

save :: UserId -> Item -> Maybe Option -> IO LicenseKey
save userId item option = return (LicenseKey "license-key-123")

sendMail :: MailTitle -> IO ()
sendMail title = do
    print title

mailTitle :: UserId -> Item -> Maybe Option -> MailTitle
mailTitle userId item option = MailTitle ((show userId) ++ " " ++ show item ++ " " ++ maybe "" show option)

apply :: UserId -> Item -> Maybe Option -> IO (Either InvalidReason LicenseKey)
apply userId item option = do
    b <- isExist userId

    let invalidReason = if b then (checkCombination item option) else Just NoUser

    case invalidReason of
        (Just reason) -> do
            -- return (Left reason)
            return $ Left reason
        Nothing -> do
            license <- save userId item option
            -- sendMail (mailTitle userId item option)
            sendMail $ mailTitle userId item option
            -- return (Right license)
            return $ Right license

main = do
    let userId = UserId "user-id-123"

    r1 <- apply userId PersonalComputer Nothing
    print r1

    r2 <- apply userId PersonalComputer $ Just Backup
    print r2

    r3 <- apply userId PersonalComputer (Just Replacement)
    print r3

    r4 <- apply userId Keyboard (Just Backup)
    print r4
