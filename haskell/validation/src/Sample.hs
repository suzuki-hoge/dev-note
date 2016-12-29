import Text.Printf
import Data.Either.Validation

purchase :: String -> String -> String -> Int -> String
purchase userId mailAddress itemName itemCount = printf "ordered [userId: %s, mailAddress: %s, itemName: %s, itemCount: %d]" userId mailAddress itemName itemCount

validateUserId :: String -> Validation [String] String
validateUserId value = if value /= ""
    then Success value
    else Failure ["UserId: empty not allowed"]

validateMailAddress :: String -> Validation [String] String
validateMailAddress value = if '@' `elem` value
    then Success value
    else Failure ["AailAddress: no atmark"]

validateItemName :: String -> Validation [String] String
validateItemName value = if value /= ""
    then Success value
    else Failure ["ItemName: empty not allowed"]

validateItemCount :: Int -> Validation [String] Int
validateItemCount value = if value /= 0
    then Success value
    else Failure ["ItemCount: zero not allowed"]

main = do
    print $ purchase
        "user-1"
        "foo@bar.com"
        "item-1"
        3

    -- "ordered [userId: user-1, mailAddress: foo@bar.com, itemName: item-1, itemCount: 3]"


    print $ purchase <$>
        validateUserId "user-1" <*>
        validateMailAddress "foo@bar.com" <*>
        validateItemName "item-1" <*>
        validateItemCount 3

    -- Success "ordered [userId: user-1, mailAddress: foo@bar.com, itemName: item-1, itemCount: 3]"


    print $ purchase <$>
        validateUserId "" <*>
        validateMailAddress "foo@bar.com" <*>
        validateItemName "item-1" <*>
        validateItemCount 3

    -- Failure ["UserId: empty not allowed"]


    print $ purchase <$>
        validateUserId "" <*>
        validateMailAddress "" <*>
        validateItemName "" <*>
        validateItemCount 0

    -- Failure ["UserId: empty not allowed","AailAddress: no atmark","ItemName: empty not allowed","ItemCount: zero not allowed"]


{-
    ghci> validateUserId ""
    Failure ["UserId: empty not allowed"]

    ghci> validateUserId "user-1"
    Success "user-1"

    ghci> validateMailAddress "foo.bar.com"
    Failure ["AailAddress: no atmark"]

    ghci> validateMailAddress "foo@bar.com"
    Success "foo@bar.com"

    ghci> validateItemName ""
    Failure ["ItemName: empty not allowed"]

    ghci> validateItemName "item-1"
    Success "item-1"

    ghci> validateItemCount 0
    Failure ["ItemCount: zero not allowed"]

    ghci> validateItemCount 3
    Success 3

ghci> validateUserId' ""
Failure ["UserId[]: not null","UserId[]: length must be 6"]
ghci> validateUserId' "user1"
Failure ["UserId[user1]: length must be 6"]
ghci> validateUserId' "user-1"
Success "user-1"
ghci> :r
[1 of 1] Compiling Main             ( Sample.hs, interpreted )
Ok, modules loaded: Main.
ghci> validateUserId' "user-1"
Success "user-1"
ghci> 

ghci> purchase <$> validateUserId "" <*> validateMailAddress "foo@bar.com" <*> validateItemName "item-1" <*> validateItemCount 0
Failure ["UserId: not null","UserId: length must be 6","ItemCount: zero not allowed"]










-}
