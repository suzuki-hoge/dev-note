module Main where

import Control.Monad.Writer
import Control.Monad.State

import Types
import IO
import Either
import Writer
import State

_io :: IO ()
_io = do
    sendMail "会社休みます"
    name <- findHospital "日本"
    b <- isOpen name
    goOr b
    

_io2 :: IO ()
_io2 = do
    sendMail "会社休みます"
    findHospital "日本" >>= isOpen >>= goOr
    

_either :: Either String Medicine
_either = do
    prescription <- goHospital "日本病院"
    getMedicine prescription


_either2 :: Either String Medicine
_either2 = do
    goHospital "日本病院" >>= getMedicine


_either3 :: Either String Medicine
_either3 = do
    goHospital' "日本病院" >>= getMedicine


aveAs3 :: Double -> Double -> Double -> Double
aveAs3 a b c = (a + b + c) / 3


_writer :: Writer [TemperatureLog] Temperature
_writer = do
    a <- measure 37.5
    b <- measure 37.2
    c <- measure 37.8

    return $ aveAs3 a b c


_writer2 :: (Temperature, [TemperatureLog])
_writer2 = runWriter $ do
    a <- measureAt 37.5 "07:00"
    b <- measureAt 37.2 "12:00"
    c <- measureAt 37.8 "15:00"

    return $ aveAs3 a b c


_writer3 :: (Temperature, [TemperatureLog])
_writer3 = runWriter $ aveAs3 <$> measure 37.5 <*> measure 37.2 <*> measure 37.8


_state :: Int -> State Health Message
_state times = do
    haveACold
    takeMedicine times
    littleCold


main :: IO ()
main = undefined
