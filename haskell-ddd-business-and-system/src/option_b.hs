data UserId = UserId { value :: String } deriving Show

data LicenseKey = LicenseKey { key :: String } deriving Show

-- isExist :: String -> IO Bool
-- isExist userId = return True

isExist :: UserId -> IO Bool
isExist userId = return True

save :: UserId -> Item -> Maybe Option -> IO LicenseKey

sendMail :: UserId -> Item -> Maybe Option -> IO ()

main = do
    -- print =<< isExist "id"

    let userId = UserId "user-id-123"
    print =<< isExist userId
