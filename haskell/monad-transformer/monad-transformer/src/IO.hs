module IO where

import Types

sendMail :: MailBody -> IO ()
sendMail = putStrLn

findHospital :: Address -> IO HospitalName
findHospital address = return $ address ++ "病院"

isOpen :: HospitalName -> IO Bool
isOpen name = return True

goOr :: Bool -> IO ()
goOr isFound
    | True  = putStrLn "病院行く"
    | False = putStrLn "病院無かった..."
