module Item.ReceivedItem.ReceivedItem where

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.ReceivedItem.ReceivedDate

data ReceivedItem = ReceivedItem {
    id       :: ItemId,
    name     :: ItemName,
    received :: ReceivedDate,
    status   :: ItemStatus
} deriving Show
