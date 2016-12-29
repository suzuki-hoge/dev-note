import RepositoryImpl
import UserId

main = do
    items <- findPurchasableItems $ UserId "id-123"
    print items

    items <- findPurchasableItems $ UserId "id-456"
    print items

    items <- findPurchasedItems $ UserId "id-123"
    print items

    items <- findPurchasedItems $ UserId "id-456"
    print items
