module Test.Main
  ( main
  ) where

import Prelude
import Effect (Effect)
import Data.Maybe (Maybe(Just))
import Data.Time.Duration (Milliseconds(Milliseconds))
import Effect.Aff (launchAff_)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec', defaultConfig)

import Node.FS.TemporarySpec as TemporarySpec

main :: Effect Unit
main = launchAff_ $ runSpec' (defaultConfig { timeout = Just (Milliseconds 2500.0) }) [ consoleReporter ] do
  TemporarySpec.spec

