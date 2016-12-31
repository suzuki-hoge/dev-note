module Form.User.FullNameForms where

import Form.Validator

import Domain.User.FullName
import Form.User.FirstNameForm as F
import Form.User.LastNameForm as L

parse :: Value -> Value -> Validated FullName
parse first last = FullName <$> F.parse first <*> L.parse last
