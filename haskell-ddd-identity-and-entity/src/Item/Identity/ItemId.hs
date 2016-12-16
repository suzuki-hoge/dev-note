module Item.Identity.ItemId where

data ItemId = ItemId { value :: String } deriving Show

itemId = ItemId "item-id-123"
