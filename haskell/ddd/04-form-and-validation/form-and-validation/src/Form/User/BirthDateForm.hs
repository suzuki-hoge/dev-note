module Form.User.BirthDateForm where

import Form.Validator as V
import Domain.User.BirthDate as B

parse :: Value -> Validated BirthDate
parse = V.parse "BirthDate" [date] B.fromString
