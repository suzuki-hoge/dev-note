module Form.Registration.PersonalDataForms where

import Form.Validator

import Domain.Registration.PersonalData
import Form.User.FullNameForms as F
import Form.User.BirthDateForm as B
import Form.Mail.MailAddressForm as M

parse :: Value -> Value -> Value -> Value -> Validated PersonalData
parse first last birth mail = PersonalData <$> F.parse first last <*> B.parse birth <*> M.parse mail
