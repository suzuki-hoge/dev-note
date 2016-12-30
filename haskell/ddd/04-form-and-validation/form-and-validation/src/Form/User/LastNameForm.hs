module Form.User.LastNameForm where

import Form.Validator as V
import Domain.User.LastName

parse :: Value -> Validated LastName
parse = V.parse "LastName" [notEmpty, lenIn 3 8] LastName
