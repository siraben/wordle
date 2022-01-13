# Solver for wordle

![Solved](./solved.png)

This is a solver for [wordle](https://www.powerlanguage.co.uk/wordle/)
using a very basic heuristic.  The initial word is chosen as the word
that contains the most frequent letters, and for every response by the
game, the words remaining that fit the reponse are ranked by overlap
with the letter frequency.  In my testing I consistently get around
3-4 attempts.

## Usage
Input the response given by the game.  `W` for wrong letter (gray),
`I` for inclusion (yellow), `E` for exact (green).

```
$ runhaskell solver.hs
2315 solutions left
Guess: soare
Enter response: WWIWI
68 solutions left
Guess: naled
Enter response: WIWEW
Solution: abbey
```
