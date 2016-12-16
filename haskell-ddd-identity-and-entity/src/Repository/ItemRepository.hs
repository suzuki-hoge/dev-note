module Repository.ItemRepository where

import Item.CancelableItem.CancelableItem
import Item.ProvisionedItem.ProvisionedItem
import Item.ShippedItem.ShippedItem

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus
import Item.ShippedItem.ArrivalScheduledDate

import User.Identity.UserId

findCancelable :: UserId -> IO [CancelableItem]
findCancelable userId = return $ [CancelableItem itemId itemName New Provisioned]

findCancelableT :: UserId -> IO ([ProvisionedItem], [ShippedItem])
findCancelableT userId = return $ ([provisionedItem], [shippedItem])
    where
        provisionedItem = ProvisionedItem itemId itemName New Provisioned
        shippedItem = ShippedItem itemId itemName Used arrivalScheduledDate Shipped
