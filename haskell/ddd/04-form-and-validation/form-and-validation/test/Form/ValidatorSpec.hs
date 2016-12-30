module Form.ValidatorSpec where

import Test.Hspec

import Data.Either.Validation

import Form.Validator

spec :: Spec
spec = do
    describe "notEmpty" $ do
        it "success" $
            notEmpty "FooForm" "foo" `shouldBe` Success "foo"

        it "failure" $
            notEmpty "FooForm" ""    `shouldBe` Failure ["FooForm[]: empty string is not allowed"]

    describe "lenMin" $ do
        it "success" $
            lenMin 3 "FooForm" "foo" `shouldBe` Success "foo"

        it "failure" $
            lenMin 3 "FooForm" "fo"  `shouldBe` Failure ["FooForm[fo]: allowed min length is 3"]

    describe "lenMax" $ do
        it "success" $
            lenMax 3 "FooForm" "foo"  `shouldBe` Success "foo"

        it "failure" $
            lenMax 3 "FooForm" "fooo" `shouldBe` Failure ["FooForm[fooo]: allowed max length is 3"]

    describe "lenIn" $ do
        it "success" $
            lenIn 2 3 "FooForm" "foo"  `shouldBe` Success "foo"

        it "failure" $
            lenIn 2 3 "FooForm" "fooo" `shouldBe` Failure ["FooForm[fooo]: allowed length is 2 to 3"]

        it "success" $
            lenIn 3 4 "FooForm" "foo"  `shouldBe` Success "foo"

        it "failure" $
            lenIn 3 4 "FooForm" "fo"   `shouldBe` Failure ["FooForm[fo]: allowed length is 3 to 4"]

    describe "regex" $ do
        it "success" $
            regex "val-[0-9]{2}" "FooForm" "val-01" `shouldBe` Success "val-01"

        it "failure" $
            regex "val-[0-9]{2}" "FooForm" "val-1"  `shouldBe` Failure ["FooForm[val-1]: allowed format is val-[0-9]{2}"]

    describe "date" $ do
        it "success" $
            date "FooForm" "2016-12/30" `shouldBe` Success "2016-12/30"

        it "failure" $
            date "FooForm" "2016-12/40" `shouldBe` Failure ["FooForm[2016-12/40]: allowed format is %Y-%m/%d, and it must be exist date"]

        it "failure" $
            date "FooForm" "20161230"   `shouldBe` Failure ["FooForm[20161230]: allowed format is %Y-%m/%d, and it must be exist date"]

    describe "datetime" $ do
        it "success" $
            datetime "FooForm" "2016-12/30-11:56:00" `shouldBe` Success "2016-12/30-11:56:00"

        it "failure" $
            datetime "FooForm" "20161230115600"      `shouldBe` Failure ["FooForm[20161230115600]: allowed format is %Y-%m/%d-%H:%M:%S, and it must be exist date"]
