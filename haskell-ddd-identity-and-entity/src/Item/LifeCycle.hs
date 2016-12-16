module Item.LifeCycle where

import Item.StockedItem.StockedItem         as StockedItem
import Item.ProvisionedItem.ProvisionedItem as ProvisionedItem
import Item.ShippedItem.ShippedItem         as ShippedItem
import Item.ReceivedItem.ReceivedItem       as ReceivedItem
import Item.CancelableItem.CancelableItem   as CancelableItem

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedStatus
import Item.ShippedItem.ArrivalScheduledDate
import Item.ReceivedItem.ReceivedDate

provision :: StockedItem -> ProvisionedItem
provision stocked = ProvisionedItem (StockedItem.id stocked) (StockedItem.name stocked) (StockedItem.stockedStatus stocked) Provisioned

ship :: ProvisionedItem -> ArrivalScheduledDate -> ShippedItem
ship provisioned date = ShippedItem (ProvisionedItem.id provisioned) (ProvisionedItem.name provisioned) (ProvisionedItem.stockedStatus provisioned) date Shipped

receive :: ShippedItem -> ReceivedDate -> ReceivedItem
receive shipped date = ReceivedItem (ShippedItem.id shipped) (ShippedItem.name shipped) date Received

returnBack :: ReceivedItem -> StockedItem
returnBack received = StockedItem (ReceivedItem.id received) (ReceivedItem.name received) Used Stocked

cancel :: CancelableItem -> StockedItem
cancel cancelable = StockedItem (CancelableItem.id cancelable) (CancelableItem.name cancelable) (CancelableItem.stockedStatus cancelable) Stocked

cancelP :: ProvisionedItem -> StockedItem
cancelP provisioned = StockedItem (ProvisionedItem.id provisioned) (ProvisionedItem.name provisioned) (ProvisionedItem.stockedStatus provisioned) Stocked

cancelS :: ShippedItem -> StockedItem
cancelS shipped = StockedItem (ShippedItem.id shipped) (ShippedItem.name shipped) (ShippedItem.stockedStatus shipped) Stocked
