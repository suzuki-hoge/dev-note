module User.Identity.UserId where

data UserId = UserId { value :: String } deriving Show

userId = UserId "user-id-123"
