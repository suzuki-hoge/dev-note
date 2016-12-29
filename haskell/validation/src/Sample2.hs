import Text.Printf
import Data.Either.Validation

purchase :: String -> String -> String -> Int -> String
purchase userId mailAddress itemName itemCount = printf "ordered [userId: %s, mailAddress: %s, itemName: %s, itemCount: %d]" userId mailAddress itemName itemCount

-- validateUserId :: String -> Validation [String] String
-- validateUserId value = if value /= ""
--     then Success value
--     else Failure ["UserId: empty not allowed"]

type FormName = String
type Value = String
type Error = String
type Validated = Validation [Error] Value
type Rule = FormName -> Value -> Validated

-- notNull :: String -> String -> Validation [String] String
notNull :: Rule
notNull name value = if value == "" then Failure [printf "%s: not null" name] else Success value

-- len :: Int -> String -> String -> Validation [String] String
len :: Int -> Rule
len size name value = if length value /= size then Failure [printf "%s: length must be %d" name size] else Success value

-- flat :: Validation [String] String -> Validation [String] String -> Validation [String] String
flat :: Validated -> Validated -> Validated
flat (Success x) (Success y) = Success x
flat (Success x) (Failure y) = Failure y
flat (Failure x) (Success y) = Failure x
flat (Failure x) (Failure y) = Failure $ x ++ y

-- validate :: String -> [(String -> String -> Validation [String] String)] -> String -> Validation [String] String
validate :: FormName -> [Rule] -> Value -> Validated
validate name rules value = foldl1 flat $ map (\f -> f name) rules <*> [value]

-- validateUserId :: String -> Validation [String] String
validateUserId :: Value -> Validated
-- validateUserId value = (\v _ -> v) <$> notNull "UserId" value <*> len 6 "UserId" value
-- validateUserId value = foldl1 flat $ map (\f -> f "UserId") [notNull, len 6] <*> [value]
validateUserId = validate "UserId" [notNull, len 6]

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

ghci> purchase <$> validateUserId' "" <*> validateMailAddress "foo@bar.com" <*> validateItemName "item-1" <*> validateItemCount 0
Failure ["UserId: not null","UserId: length must be 6","ItemCount: zero not allowed"]










-}
