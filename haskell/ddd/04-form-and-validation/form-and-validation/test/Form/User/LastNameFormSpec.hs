module Form.User.LastNameFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.User.LastNameForm
import Domain.User.LastName

spec :: Spec
spec = do
    describe "parse" $ do
        it "success" $
            parse "Doe" `shouldBe` Success (LastName "Doe")

        it "failure empty value" $
            parse "" `shouldBe` Failure [
                "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
            ]
