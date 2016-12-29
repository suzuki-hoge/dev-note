check int = case int of
    (Just x) -> do
        putStrLn "just!"
        print x

    Nothing  -> do
        putStrLn "nothing"

main = do
    check (Just 5)
