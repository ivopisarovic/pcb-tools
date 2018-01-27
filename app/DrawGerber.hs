module Main where

import Options.Applicative
import Data.Semigroup ((<>))

import Diagrams.Prelude
import Diagrams.Backend.Rasterific.CmdLine
--import Diagrams.Backend.SVG.CmdLine
import Diagrams.TwoD.Vector
import Diagrams.TwoD.Offset
import Diagrams.Prelude

import Control.Lens.Cons ((<|))
import Text.Pretty.Simple (pPrint)
import Data.Scientific hiding (scientific)
import qualified Data.ByteString.Char8 as BS

import Data.Gerber.Parser (parseGerber)
import Data.Gerber.Interpreter -- (evalGerberCommands)

data DrawerOpts = DrawerOpts
  { inputFile :: FilePath
  } deriving (Show, Eq)

optionParser :: Parser DrawerOpts
optionParser = DrawerOpts
    <$> argument str   (metavar "FILE")

programOptions :: ParserInfo DrawerOpts
programOptions = info (optionParser <**> helper)
  ( fullDesc
  <> progDesc "Print a greeting for TARGET"
  <> header "hello - a test for optparse-applicative" )

programCore :: DrawerOpts -> IO ()
programCore options = do
  contents <- BS.readFile $ inputFile options
  let parsed = parseGerber contents
  case parsed of
    Left why -> error $ "unable to parse, err: " ++ show why
    Right commands -> do
      let m = evalGerberCommands commands
          drawings = m ^. draws
      --pPrint drawings
      mainWith $ drawGerber $ drawings
      return ()
  return ()

drawGerber :: [([Scientific], b0, Located (Trail V2 Double))] -> Diagram B
drawGerber draws = mconcat $ fmap widenTrace $ replicate 1000 (draws !! 10)
  where
    widenTrace = (\(a,b,c) -> c # (e (toRealFloat $ head a)) # stroke # lc blue # lw ultraThin)
    -- (lineWidth $ local $ 1.0 *(toRealFloat $ head a) ))
    e thickness = expandTrail' opts (254*thickness)
    opts = with   -- & expandJoin .~ LineJoinRound
                  & expandCap  .~ LineCapRound
    trails = fmap third draws
    first = (\(a,b,c) -> a)
    third = (\(a,b,c) -> c)

main :: IO ()
--main = programCore =<< execParser programOptions
main = do
  programCore $ DrawerOpts "example/izolator.gbr"
