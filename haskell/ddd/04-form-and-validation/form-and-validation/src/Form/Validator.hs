module Form.Validator where

import Data.Either.Validation
import Text.Regex.Posix
import Data.Time
import Data.Time.Format

type FormName = String
type Value = String
type Message = String
type Error = String
type Validated a = Validation [Error] a
type Rule = FormName -> Value -> Validated Value

parse :: FormName -> [Rule] -> (Value -> a) -> Value -> Validated a
parse name rules constructor value = constructor <$> validate name rules value

validate :: FormName -> [Rule] -> Value -> Validated Value
validate name rules value = head <$> sequenceA (map (\f -> f name) rules <*> [value])

mkErrors :: FormName -> Value -> Message -> [Error]
mkErrors name value message = [name ++ "[" ++ value ++ "]: " ++ message]

notEmpty :: Rule
notEmpty name value
    | value /= "" = Success value
    | otherwise   = Failure $ mkErrors name value "empty string is not allowed"

lenMin :: Int -> Rule
lenMin x name value
    | x <= length value = Success value
    | otherwise         = Failure $ mkErrors name value $ "allowed min length is " ++ show x

lenMax :: Int -> Rule
lenMax x name value
    | length value <= x = Success value
    | otherwise         = Failure $ mkErrors name value $ "allowed max length is " ++ show x

lenIn :: Int -> Int -> Rule
lenIn x y name value
    | length value `elem` [x..y] = Success value
    | otherwise         = Failure $ mkErrors name value $ "allowed length is " ++ show x ++ " to " ++ show y

regex :: String -> Rule
regex x name value
    | value =~ x = Success value
    | otherwise  = Failure $ mkErrors name value $ "allowed format is " ++ x

asFormatted :: String -> Rule
asFormatted format name value = case parse value of
    (Just _) -> Success value
    Nothing  -> Failure $ mkErrors name value $ "allowed format is " ++ format ++ ", and it must be exist date"
    where
        parse :: String -> Maybe UTCTime
        parse = parseTimeM True defaultTimeLocale format

date :: Rule
date = asFormatted "%Y-%m/%d"

datetime :: Rule
datetime = asFormatted "%Y-%m/%d-%H:%M:%S"
