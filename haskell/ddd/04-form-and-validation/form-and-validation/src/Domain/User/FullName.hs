module Domain.User.FullName where

import Domain.User.FirstName
import Domain.User.LastName

data FullName = FullName FirstName LastName deriving (Show, Eq)
