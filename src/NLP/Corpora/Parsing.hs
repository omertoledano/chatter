{-# LANGUAGE OverloadedStrings #-}
module NLP.Corpora.Parsing where

import qualified Data.Text as T
import Data.Text (Text)

import NLP.Tokenize
import NLP.Types

-- | Read a POS-tagged corpus out of a Text string of the form:
-- "token\/tag token\/tag..."
--
-- >>> readPOS "Dear/jj Sirs/nns :/: Let/vb"
-- [("Dear",JJ),("Sirs",NNS),(":",Other ":"),("Let",VB)]
--
-- TODO update haddock
readPOS :: POS t => Text -> TaggedSentence t
readPOS str = applyTags tokenizedSentence (map snd tagPairs)
    where
      tokenizedSentence = runTokenizer whitespace $ T.unwords $ map fst tagPairs

      tagPairs = map toTagged $ T.words str

-- | Read a 'ChunkedSentence' from a pretty-printed variant.
--
-- The dual of 'prettyShow chunkedSentence'
--
-- >>> readChunk "[NP The/DT dog/NN] and/CC [NP the/DT fox/NN] [VP jumped/VBD]./." :: ChunkedSentence B.Tag B.Chunk
-- ChunkedSentence ...
--
-- Grammar:
--
-- S          ::= Token | ChunkStart | Nothing
-- Token      ::= CharSeq "/" POSTag
-- CharSeq    ::= Char MChar
-- Char       ::= [any character not in {'[',']','/', whitespace}]
-- MChar      ::= Char | Nothing
-- POSTag     ::= CharSeq
-- ChunkStart ::= "[" CharSeq " "
-- ChunkEnd   ::= "]"
--
-- Lexemes:
--  - CharSeq    (someChar+)
--  - ChunkStart ("[" someChar+)
--  - ChunkEnd ("]")
--  - Token  (someChar+)
--  - POSTag ("/"someChar+)
--  - ignore whitespace
--
readChunk :: (Chunk chunk, POS pos) => Text -> Either Error (ChunkedSentence pos chunk)
readChunk str = parseChunkedSentence str

-- | Read a standard POS-tagged corpus with one sentence per line, and
-- one POS tag after each token.
readCorpus :: POS pos => Text -> [TaggedSentence pos]
readCorpus corpus = map readPOS $ T.lines corpus

toTagged :: POS pos => Text -> (Text, pos)
toTagged txt | "/" `T.isInfixOf` txt =
               let (tok, tagStr) = T.breakOnEnd "/" (T.strip txt)
               in  (safeInit tok, safeParsePOS tagStr)
             | otherwise = (txt, tagUNK)


-- | Returns all but the last element of a string, unless the string
-- is empty, in which case it returns that string.
safeInit :: Text -> Text
safeInit str | T.length str == 0 = str
             | otherwise         = T.init str
