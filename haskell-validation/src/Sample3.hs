import Text.Printf
import Data.Either.Validation

type FormName = String
type Value = String
type Error = String
type Validated = Validation [Error] Value
type Rule = FormName -> Value -> Validated

notNull :: Rule
notNull name value = if value == "" then Failure [printf "%s: not null" name] else Success value

len :: Int -> Rule
len size name value = if length value /= size then Failure [printf "%s: length must be %d" name size] else Success value

flat :: Validated -> Validated -> Validated
flat (Success x) (Success y) = Success x
flat (Success x) (Failure y) = Failure y
flat (Failure x) (Success y) = Failure x
flat (Failure x) (Failure y) = Failure $ x ++ y

validate :: FormName -> [Rule] -> Value -> Validated
validate name rules value = foldl1 flat $ map (\f -> f name) rules <*> [value]

validateUserId :: Value -> Validated
validateUserId = validate "UserId" [notNull, len 6]
