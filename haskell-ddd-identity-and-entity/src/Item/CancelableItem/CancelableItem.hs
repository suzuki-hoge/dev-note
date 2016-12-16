module Item.CancelableItem.CancelableItem where

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus

data CancelableItem = CancelableItem { id :: ItemId, name :: ItemName, stockedStatus :: StockedStatus, status :: ItemStatus } deriving Show
