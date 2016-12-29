module RepositoryImpl where

import Control.Exception

import Mapper

import UserId
import Item

findPurchasedItems :: UserId -> IO Item
findPurchasedItems userId = do
    res <- findByUserId userId
    case res of
        (Just x) -> return x
        Nothing  -> throwIO $ userError "not found"

findPurchasableItems :: UserId -> IO (Maybe Item)
findPurchasableItems userId = do
    findByUserId userId
