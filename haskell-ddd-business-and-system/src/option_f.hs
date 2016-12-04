isExist :: UserId -> IO Bool
checkCombination :: Item -> Option -> Maybe InvalidReason
mailTitle :: UserId -> Item -> Option -> String
save :: UserId -> Item -> Option -> IO LicenseKey
sendMail :: UserId -> Item -> Option -> IO ()
apply :: UserId -> Item -> Option -> IO (Either InvalidReason LicenseKey)
