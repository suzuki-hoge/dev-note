module Item.ProvisionedItem.ProvisionedItem where

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus

data ProvisionedItem = ProvisionedItem {
    id            :: ItemId,
    name          :: ItemName,
    stockedStatus :: StockedStatus,
    status        :: ItemStatus
} deriving Show
