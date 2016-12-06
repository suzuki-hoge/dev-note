isExist :: UserId -> IO Bool
checkCombination :: Item -> Option -> Maybe InvalidReason
mailTitle :: UserId -> Item -> Option -> MailTitle
save :: UserId -> Item -> Option -> IO LicenseKey
sendMail :: MailTitle -> IO ()
apply :: UserId -> Item -> Option -> IO (Either InvalidReason LicenseKey)



find :: UserId -> IO (Maybe User)
isExist :: User -> Bool

isExist :: CheckForExist -> IO Bool

type Allocated = (UserId, Password)
