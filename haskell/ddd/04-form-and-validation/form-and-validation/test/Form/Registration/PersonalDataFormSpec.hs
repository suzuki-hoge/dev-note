module Form.Registration.PersonalDataFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.Registration.PersonalDataForm
import Domain.Registration.PersonalData
import Domain.User.FullName
import Domain.User.FirstName
import Domain.User.LastName
import Domain.User.BirthDate as B
import Domain.Mail.MailAddress

spec :: Spec
spec = do
    describe "parse" $ do
        it "success" $ do
            let full = FullName (FirstName "John") (LastName "Doe")
            let birth = B.fromString "1990-01/23"
            let mail = MailAddress "foo.bar@gmail.com"

            parse "John" "Doe" "1990-01/23" "foo.bar@gmail.com" `shouldBe` Success (PersonalData full birth mail)

        it "failure with one error" $
            parse "John" "Doe" "1990-12/34" "foo.bar@gmail.com" `shouldBe` Failure [
                "BirthDate[1990-12/34]: allowed format is %Y-%m/%d, and it must be exist date"
            ]

        it "failure with more than two errors" $
            parse "" "" "" "" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
              , "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
              , "BirthDate[]: allowed format is %Y-%m/%d, and it must be exist date"
              , "MailAddress[]: empty string is not allowed"
              , "MailAddress[]: atmark must be there"
            ]
