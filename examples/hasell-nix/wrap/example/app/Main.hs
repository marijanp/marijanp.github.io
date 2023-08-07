module Main (main) where

import MyLib (someFunc)
import System.Process (callProcess)

main :: IO ()
main = do
    callProcess "hello" []
    someFunc
