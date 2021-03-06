-- Oskar Casselryd
-- Trolle Geuna
-- Senast ändrad 2015-09-22

module F2 where
import Data.List

-- skapar en data typ av typen typ som antingen kan vara protein eller dna
data Typ = PROTEIN | DNA deriving(Show,Eq)

-- skapar en molseq
data MolSeq = MolSeq { sekvensnamn :: String, sekvens :: String, typ :: Typ }deriving(Show)



-- UPPGIFT 2

dna =['A','C','G','T']

string2seq :: String->String->MolSeq
string2seq namn sekvens
  | checkDNA sekvens = MolSeq namn sekvens DNA
  | otherwise = MolSeq namn sekvens PROTEIN

checkDNA :: String -> Bool
checkDNA [] = True
checkDNA(h:t)
  | elem h dna = checkDNA(t)
  | otherwise = False



seqName :: MolSeq -> String
seqName m = sekvensnamn m

seqSequence :: MolSeq -> String
seqSequence m = sekvens m

seqLength :: MolSeq -> Int
seqLength m = length (sekvens m)

seqType :: MolSeq -> Typ
seqType m = typ m



seqDistance :: MolSeq -> MolSeq -> Double
seqDistance n m
-- kollar om båda molseq är utav samma typ
  | checkDNA (sekvens n) /= checkDNA (sekvens m) = error "Can't compare DNA and PROTEIN"
-- OM checkDNA kör seqdiff på sekvensen dela sedan detta med längden på sekvensen för att sedan köra junkeskantor på det
  | checkDNA (seqSequence n) == True  = jukesCantor(fromIntegral(seqDiff(seqSequence n) (seqSequence m)) / fromIntegral(seqLength n)) -- kalla funktionen för dna här
-- OM det är ett protein kör seqdiff på sekvensen dela sedan detta med längden på sekvensen för att sedan köra poisonmodellen på det
  | otherwise = poissonModellforProtein(fromIntegral(seqDiff(seqSequence n) (seqSequence m)) / fromIntegral(seqLength n)) -- kalla funktionen för protein här


-- För dna
jukesCantor:: Double -> Double
jukesCantor a
  | a > 0.74 = 3.3
  | otherwise = -(3/4)*log(1-((4*a)/3))


poissonModellforProtein:: Double -> Double
poissonModellforProtein a
  | a <= 0.94 = -(19/20)*log(1-((20*a)/19))
  | otherwise = 3.7

-- Jämför varje head i två strängar med varandra.
-- När dessa är olika så adderas et till int
seqDiff :: String -> String -> Int
seqDiff [] [] = 0
seqDiff a b
  | head a == head b = 0 + seqDiff (tail a) (tail b)
  | otherwise = 1 + seqDiff (tail a) (tail b)



-- UPPGIFT 3
-- en typ Matris som inehåller tupler med char, int
type Matris = [[(Char, Int)]]
-- Skapar en dataprofil som heter Profile
data Profile = Profile { m :: Matris, mTyp :: Typ, antalSekvenser :: Int, namn :: String }deriving(Show)



--TODO: se kommentarerna i funktionen
-- Är våran Matrix fel???
-- Kanske finns ett snyggare/bättre sätt

-- Gör en profil utav en lista utav molseqs och ett namn
molseqs2profile:: String -> [MolSeq] -> Profile
molseqs2profile a b = Profile m mTyp antalSekvenser namn
  where
    m = makeProfileMatrix b
    mTyp = seqType (head b)
    antalSekvenser = length b
    namn = a



nucleotides = "ACGT"
aminoacids = sort "ARNDCEQGHILKMFPSTWYVX"

makeProfileMatrix :: [MolSeq] -> Matris
makeProfileMatrix [] = error "Empty sequence list"
makeProfileMatrix sl = res
  where 
    t = seqType (head sl)
    defaults = 
      if (t == DNA) then
        -- skapar en lista utav tupler [(A,0),(C,0),(G,0),...]
        zip nucleotides (replicate (length nucleotides) 0) -- Rad (i)
      else 
        -- samma som rad i fast med aminosyror
        zip aminoacids (replicate (length aminoacids) 0)   -- Rad (ii)
    -- strs är en lista som innehåller alla sekvenser som matrisen skapas utav
    strs = map seqSequence sl                              -- Rad (iii)
    -- transponera listan strs så att vi får en lista A där As första element
    -- består utav första elementet ur varje sekvent. Och så vidare. Skapar en sorterad map och gruperar elementen så att alla C t.ex står brevid varandra
    tmp1 = map (map (\x -> ((head x), (length x))) . group . sort)
               (transpose strs)                            -- Rad (iv)
    equalFst a b = (fst a) == (fst b)
    res = map sort (map (\l -> unionBy equalFst l defaults) tmp1)




profileName :: Profile -> String
profileName n = namn n



-- Eftersom våran matris är [[(Char, Int)]]
-- Bör vi väll plocka ut en [(Char, Int)] på den position vi vill undersöka
-- Sedan hämta ut det värde för rätt Char
profileFrequency :: Profile -> Int -> Char -> Double
profileFrequency (Profile m _ antalSekvenser _) position tecken = fromIntegral number / fromIntegral antalSekvenser
  where
    number = helpprofileFrequency (m !! position) tecken

-- Tecknet _MÅSTE_ finnas i sekvensen för att denna funktion ska fungera.
helpprofileFrequency :: [(Char, Int)] -> Char -> Int
helpprofileFrequency (huvud: svans) tecken
  | tecken == fst huvud = snd huvud
  | otherwise = helpprofileFrequency svans tecken




-- ANVÄND PROFILEFREQUENCY! Se till att det är rätt matriser som jämförs! Det ska vara doubles, inte int!

-- Plocka ut matriserna från profilerna och kalla hjälpfunktion.
profileDistance :: Profile -> Profile -> Double
profileDistance (Profile m1 _ antalSekvenser1 _) (Profile m2 _ antalSekvenser2 _) = (helpDistance m1 m2 antalSekvenser1 antalSekvenser2)

-- Kör igenom listorna i matrisen. Alltså de olika teckenpositionerna.
helpDistance :: Matris -> Matris -> Int -> Int -> Double
helpDistance [] [] _ _ = 0
helpDistance (h1:t1) (h2:t2) antalSekvenser1 antalSekvenser2 = abs (helpDistance2 h1 h2 antalSekvenser1 antalSekvenser2) + (helpDistance t1 t2 antalSekvenser1 antalSekvenser2) -- Kalla hd2

-- Jämför varje tuple som utgör matrisen. Dvs hur många av varje tecken som finns på positionen.
helpDistance2 :: [(Char, Int)] -> [(Char, Int)] -> Int -> Int -> Double
helpDistance2 [] [] _ _ = 0
helpDistance2 (h1:t1) (h2:t2) antalSekvenser1 antalSekvenser2 = abs((fromIntegral (snd h1) / fromIntegral antalSekvenser1) - (fromIntegral (snd h2) / fromIntegral antalSekvenser2)) + (helpDistance2 t1 t2 antalSekvenser1 antalSekvenser2)









class Evol a where
  distance :: a -> a -> Double
  name :: a -> String 
  distanceMatrix :: [a] -> [(String, String, Double)]
  distanceMatrix[] = []
  --kallar på helpDistanceMatrix och sedan på distanceMatrix med tail
  distanceMatrix a = helpDistanceMatrix a 0 ++ distanceMatrix (tail a)
  helpDistanceMatrix :: [a] -> Int ->[(String, String, Double)]
  helpDistanceMatrix a nummer
    |nummer < length a = (name ett , name tva, distance ett tva) : helpDistanceMatrix a (nummer+ 1)
    |otherwise = []
    where
      ett = head a
      tva = a !! nummer


    





instance Evol MolSeq where
  name = seqName
  distance = seqDistance

instance Evol Profile where
  name = profileName
  distance = profileDistance



