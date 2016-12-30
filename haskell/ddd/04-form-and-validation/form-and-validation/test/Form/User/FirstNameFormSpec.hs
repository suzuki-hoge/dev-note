module Form.User.FirstNameFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.User.FirstNameForm
import Domain.User.FirstName

spec :: Spec
spec = do
    describe "parse" $ do
        it "success" $
            parse "John" `shouldBe` Success (FirstName "John")

        it "failure empty value" $
            parse "" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
            ]
