module Item.StockedItem.StockedItem where

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus

data StockedItem = StockedItem {
    id            :: ItemId,
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    status        :: ItemStatus
} deriving Show
