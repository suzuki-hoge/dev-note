module Item.ShippedItem.ShippedItem where

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus

import Item.ShippedItem.ArrivalScheduledDate

data ShippedItem = ShippedItem {
    id            :: ItemId, 
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    arrival       :: ArrivalScheduledDate,
    status        :: ItemStatus
} deriving Show
