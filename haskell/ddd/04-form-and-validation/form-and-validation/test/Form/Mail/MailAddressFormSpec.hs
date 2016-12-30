module Form.Mail.MailAddressFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.Mail.MailAddressForm
import Domain.Mail.MailAddress

spec :: Spec
spec =
    describe "parse" $ do
        it "success" $
            parse "foo.bar@gmail.com" `shouldBe` Success (MailAddress "foo.bar@gmail.com")

        it "failure empty value" $
            parse "" `shouldBe` Failure [
                "MailAddress[]: empty string is not allowed"
              , "MailAddress[]: atmark must be there"
            ]
