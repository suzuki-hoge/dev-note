module Form.User.BirthDateFormSpec where

import Test.Hspec

import Data.Either.Validation

import Form.User.BirthDateForm
import Domain.User.BirthDate as B

spec :: Spec
spec =
    describe "parse" $ do
        it "success" $
            parse "2016-12/30" `shouldBe` Success (B.fromString "2016-12/30")

        it "failure invalid format" $
            parse "20161230"   `shouldBe` Failure ["BirthDate[20161230]: allowed format is %Y-%m/%d, and it must be exist date"]

        it "failure non existence date" $
            parse "2016-12/32" `shouldBe` Failure ["BirthDate[2016-12/32]: allowed format is %Y-%m/%d, and it must be exist date"]
