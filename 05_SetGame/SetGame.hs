module SetGame where

import Control.Applicative
import Data.List
import System.Random
import Data.Ord
import Data.Maybe

data Colour = Red | Purple | Green       deriving (Eq, Ord, Enum, Bounded, Show)
data Shape  = Diamond | Squiggle | Oval  deriving (Eq, Ord, Enum, Bounded, Show)
data Fill   = Solid | Open | Stripe      deriving (Eq, Ord, Enum, Bounded, Show)
data Number = One | Two | Three          deriving (Eq, Ord, Enum, Bounded, Show)

data Card = Card
  { colour :: Colour
  , shape  :: Shape
  , fill   :: Fill
  , number :: Number
  } deriving (Eq, Ord)

data GameState = GameState 
  { hand :: [Card]
  , deck :: [Card]
  , sets :: [(Card, Card, Card)]
  } deriving (Show)

instance Show Card where
  show (Card c s f n) = unwords [show n, show c, show f, show s] 

fullDeck :: [Card]
fullDeck = Card <$> allEnum <*> allEnum <*> allEnum <*> allEnum

allEnum :: (Enum a, Bounded a) => [a]
allEnum = [minBound .. maxBound]

shuffle :: (RandomGen g) => g -> [a] -> [a]
shuffle g = map snd . sortBy (comparing fst) . zip (randoms g :: [Double])

isSet :: Card -> Card -> Card -> Bool
isSet card1 card2 card3 = good colour && good shape && good fill && good number
  where
    good f = (a == b && a == c) || (a /= b && a /= c && b /= c)
      where
        a = f card1
        b = f card2
        c = f card3

findSet :: [Card] -> Maybe ((Card, Card, Card), [Card])
findSet h = listToMaybe
  [ ((c1, c2, c3), h')
  | c1 : h1 <- tails h
  , c2 : h2 <- tails h1
  , c3 : _  <- tails h2
  , isSet c1 c2 c3
  , let h' = h \\ [c1, c2, c3]
  ] 

main :: IO()
main = do
  g <- newStdGen
  mapM_ print $ runGame g

initialState :: RandomGen r => r -> GameState
initialState r = GameState {hand = [], deck = shuffle r fullDeck, sets = []}

runGame :: RandomGen r => r -> [(Card, Card, Card)]
runGame = sets . until done play . initialState

done :: GameState -> Bool
done s = null (hand s) && null (deck s)

play :: GameState -> GameState
play (GameState h d ss)
  | Just (s, h') <- findSet h = GameState h' d (s : ss)
  | c1 : c2 : c3 : d' <- d    = GameState (c1 : c2 : c3 : h) d' ss
  | otherwise                 = GameState [] [] ss
