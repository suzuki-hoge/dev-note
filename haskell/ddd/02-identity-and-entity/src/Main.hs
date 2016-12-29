import qualified Item.LifeCycle as LifeCycle

import Item.Identity.ItemId
import Item.ItemName
import Item.ItemStatus

import Item.StockedItem.StockedItem

import Item.StockedItem.StockedStatus
import Item.ShippedItem.ArrivalScheduledDate
import Item.ReceivedItem.ReceivedDate

import User.Identity.UserId

import Repository.ItemRepository

main = do
    let stockedItem = StockedItem itemId itemName New Stocked
    let provisionedItem = LifeCycle.provision stockedItem
    let shippedItem = LifeCycle.ship provisionedItem arrivalScheduledDate
    let receivedItem = LifeCycle.receive shippedItem receivedDate

    let returnBackedItem = LifeCycle.returnBack receivedItem

    print stockedItem
    print provisionedItem
    print shippedItem
    print receivedItem

    print returnBackedItem

    cancelables <- findCancelable userId
    let canceledItems = map LifeCycle.cancel cancelables

    print cancelables
    print canceledItems

    (ps, ss) <- findCancelableT userId
    let canceledItemPs = map LifeCycle.cancelP ps
    let canceledItemSs = map LifeCycle.cancelS ss

    print canceledItemPs
    print canceledItemSs


    -- キャンセル可能はProvisiond/Shipped
    -- 動詞/動詞ed
    -- 1つでやったらmaybeになるか、status = provisioned { status } | shipped { arrival }
    -- statusってドメイン？datasourceだけで良くない？
    -- cancellable -> ([provisioned], [shipped]) はだめかな？
