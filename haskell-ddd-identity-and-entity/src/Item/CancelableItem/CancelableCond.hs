module CancelableCond where

import Item.ItemStatus

data CancelableCond = CancelableCond { status :: [ItemStatus] } deriving Show

cancelableCond = CancelableCond [Provisioned, Shipped]
