module Domain.Registration.PersonalData where

import Domain.User.FullName
import Domain.User.BirthDate
import Domain.Mail.MailAddress

data PersonalData = PersonalData FullName BirthDate MailAddress deriving (Show, Eq)
