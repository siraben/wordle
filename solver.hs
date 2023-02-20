{-# LANGUAGE TupleSections #-}
{-# OPTIONS_GHC -Wno-typed-holes #-}

module Main where

import Control.Applicative
import Control.Monad
import Data.Function
import Data.List
import qualified Data.List as M
import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe
import Data.Ord
import Data.Set (Set)
import qualified Data.Set as S


--- hint returned by wordle
--          exact   invalid   wrong
data Hint = E Char | I Char | W Char deriving (Show, Eq)

freqs :: Ord a => [a] -> Map a Int
freqs = M.fromListWith (+) . map (,1)

fits :: [Hint] -> String -> Bool
fits hs s = null (ins \\ s) && and (zipWith f hs s)
  where
    ins = g =<< hs
    g (I c) = [c]
    g (E c) = [c]
    g _ = []
    -- if wrong letter, check if in ins
    -- if it is in ins, then that means the letter cannot be used twice
    f (W c) _
      | c `elem` ins = length (filter (== c) ins) == length (filter (== c) s)
      | otherwise = True
    f (E c) c' = c == c'
    f (I c) c' = c `elem` s

-- guessing algorithm
-- first match exact ones, otherwise do a left to right scan
guess g s = fromJust $ zipWithM (<|>) exacts (map Just (go g s (s \\ exs)))
  where
    exs = fromMaybe [] (mconcat (map (fmap f) exacts))
    f (E c) = [c]
    f _ = []
    exacts = zipWith (\x y -> if x == y then Just (E x) else Nothing) s g
    go (c : cs) s'@(x : xs) l
      | c == x = E c : go cs xs l
      | c `elem` s = if c `elem` l then I c : go cs xs (l \\ [c]) else W c : go cs xs l
      | c /= x = W c : go cs xs l
    go _ _ _ = []

topFiveLetters l = S.fromList $ fst <$> take 5 (sortBy (compare `on` Down . snd) (M.toList (freqs (concat l))))

cans :: Ord a => [[a]] -> [a]
cans [x] = x
cans l = maximumBy (compare `on` S.size . S.intersection tl . S.fromList) l
  where
    tl = topFiveLetters l

turn c h l = (cans g, g)
  where
    g = filter (\w -> fits h w && guess c w == h) l

parseRes = map f
  where
    f 'E' = E
    f 'W' = W
    f 'I' = I
    f _ = undefined

play l = go firstWord l
  where
    firstWord = cans l
    go w l = do
      putStrLn (show (length l) ++ " solutions left")
      putStrLn ("Guess: " ++ w)
      putStr "Enter response: "
      r <- getLine
      let res = flip (zipWith ($)) w . parseRes $ r
      let (w', l') = turn w res l
      case l' of
        [sol] -> putStrLn $ "Solution: " ++ sol
        [] -> putStrLn "No solution!"
        _ -> go w' l'

play' l firstWord hidden = go firstWord l [firstWord]
  where
    tl = topFiveLetters l
    firstWord = cans l
    go _ [sol] acc = reverse acc
    go _ [] acc = []
    go w l acc = go w' (if w' == hidden then [w'] else l') (w' : acc)
      where
        r = showGuess (guess w hidden)
        res = flip (zipWith ($)) w . parseRes $ r
        (w', l') = turn w res l

showGuess :: [Hint] -> [Char]
showGuess = map f
  where
    f (W _) = 'W'
    f (E _) = 'E'
    f (I _) = 'I'

main :: IO ()
main = do
  putStrLn "Use the guess returned by the solver and input 5 letters {W,E,I}."
  putStrLn "W = Wrong, E = Exact, I = Included"
  s <- lines <$> readFile "solutions.txt"
  play s
  -- code to evaluate to performance of the solver
  -- let l = map (length . play' s "aorta") s
  -- print $ fromIntegral (sum l) / fromIntegral (length l)
