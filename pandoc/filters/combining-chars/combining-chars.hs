#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}

import Text.Pandoc.JSON
import Text.Pandoc.JSON (Inline (Math))

import Data.Text
import Data.String.Conversions
import Data.Stringable
import Data.List
import Data.Bool
import Data.ByteString.UTF8 as BSU

-- Helpful resource on regex: 
-- https://www.generacodice.com/en/articolo/676554/haskell+regex+substitution
import Text.Regex.PCRE.Light as RL (compile, utf8)
import Text.Regex.PCRE.Heavy as RH (gsub, (=~), re)

mathFilter :: (Text -> Text) -> Inline -> Inline
mathFilter f (Math t e) = Math t (f e)
mathFilter _ x = x

main :: IO ()
main = toJSONFilter (mathFilter combiningChar)

hex :: String -> String -> Bool
hex h s = s =~ rx where
    rr = BSU.fromString $ "\\x{" ++ h ++ "}"
    rx = compile rr [RL.utf8]

command :: String -> String
command x = 
    if hex "0301" x then "acute"     else
    if hex "0302" x then "hat"       else
    if hex "0303" x then "tilde"     else
    if hex "0304" x then "bar"       else
    if hex "0305" x then "bar"       else
    if hex "0306" x then "breve"     else
    if hex "0307" x then "dot"       else
    if hex "0308" x then "ddot"      else
    if hex "030A" x then "mathring"  else
    if hex "030B" x then "dacute"    else
    if hex "20D7" x then "vec"       else
    if hex "0332" x then "underline" else
    if hex "0333" x then "uuline"    else
    if hex "0336" x then "msout"     else
    if hex "0338" x then "slashed"   else
    ("donthaveacommandforx" ++ x)

replacer :: [String] -> String
replacer xs = "\\" ++ cmd ++ "{" ++ chr ++ "}" where
    cmd = command $ xs !! 1
    chr = xs !! 0

combiningChar :: Text -> Text
combiningChar text = pack $ gsub rx replacer (unpack text) where
    rx = compile "(\\p{L}|\\p{N})(\\x{0301}|\\x{0306}|\\x{030B}|\\x{030A}|\\x{0303}|\\x{0307}|\\x{0308}|\\x{0304}|\\x{0305}|\\x{0302}|\\x{20D7}|\\x{0332}|\\x{0333}|\\x{0336}|\\x{0338})" [RL.utf8]
