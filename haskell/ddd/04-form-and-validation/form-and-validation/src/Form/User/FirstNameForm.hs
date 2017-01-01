module Form.User.FirstNameForm where

import Form.Validator as V
import Domain.User.FirstName

parse :: Value -> Validated FirstName
parse = V.parse "FirstName" [notEmpty, lenIn 3 8] FirstName
