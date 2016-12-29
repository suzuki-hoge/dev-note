module Mapper where

import UserId
import Item

findByUserId :: UserId -> IO (Maybe Item)
findByUserId userId = if userId == UserId "id-123"
    then return $ Just Item
    else return Nothing
