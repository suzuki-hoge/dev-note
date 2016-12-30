module Form.User.FullNameFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.User.FullNameForm
import Domain.User.FullName
import Domain.User.FirstName
import Domain.User.LastName

spec :: Spec
spec = do
    describe "parse" $ do
        it "success" $
            parse "John" "Doe" `shouldBe` Success (FullName (FirstName "John") (LastName "Doe"))

        it "failure empty first name" $
            parse "" "Doe" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
            ]

        it "failure empty last name" $
            parse "John" "" `shouldBe` Failure [
                "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
            ]

        it "failure empty both name" $
            parse "" "" `shouldBe` Failure [
                "FirstName[]: empty string is not allowed"
              , "FirstName[]: allowed length is 3 to 8"
              , "LastName[]: empty string is not allowed"
              , "LastName[]: allowed length is 3 to 8"
            ]
