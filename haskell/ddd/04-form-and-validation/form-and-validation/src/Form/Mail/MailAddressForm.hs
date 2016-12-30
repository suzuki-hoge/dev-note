module Form.Mail.MailAddressForm where

import Data.Either.Validation

import Form.Validator as V
import Domain.Mail.MailAddress

parse :: Value -> Validated MailAddress
parse = V.parse "MailAddress" [notEmpty, hasAtmark] MailAddress

hasAtmark :: Rule
hasAtmark name value
    | '@' `elem` value = Success value
    | otherwise   = Failure $ mkErrors name value "atmark must be there"
