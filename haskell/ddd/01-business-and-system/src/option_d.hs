data Item = PersonalComputer | Keyboard deriving (Show, Eq)

data Option = Backup | Replacement deriving (Show, Eq)

data InvalidReason = PersonalComputerAndReplacement | KeyboardAndBackup deriving (Show, Eq)

-- checkCombination :: Item -> Option -> String
-- checkCombination item option = case (item, option) of
--     (PersonalComputer, Replacement) -> "PCに交換オプションは付加出来ません"
--     (Keyboard, Backup) -> "キーボードにバックアップオプションは付加出来ません"
--     _ -> ""

checkCombination :: Item -> Maybe Option -> Maybe InvalidReason
checkCombination item option = case (item, option) of
    (_, Nothing) -> Nothing
    (PersonalComputer, Just Replacement) -> Just PersonalComputerAndReplacement
    (Keyboard, Just Backup) -> Just KeyboardAndBackup
    _ -> Nothing

main = do
    print $ checkCombination PersonalComputer Nothing
    print $ checkCombination PersonalComputer (Just Replacement)
    print $ checkCombination Keyboard (Just Backup)
    print $ checkCombination PersonalComputer (Just Backup)
