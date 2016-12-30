module Domain.User.BirthDate
( BirthDate
, fromString
) where

import Data.Maybe
import Data.Time
import Data.Time.Format

data BirthDate = BirthDate UTCTime deriving (Show, Eq)

fromString :: String -> BirthDate
fromString value = BirthDate $ fromJust date
    where
        date :: Maybe UTCTime
        date = parseTimeM True defaultTimeLocale "%Y-%m/%d" value

