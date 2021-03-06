{-|
Module      : IRTS.System
Description : Utilities for interacting with the System.
Copyright   :
License     : BSD3
Maintainer  : The Idris Community.
-}
{-# LANGUAGE CPP #-}
module IRTS.System( getDataFileName
                  , getCC
                  , getLibFlags
                  , getIdrisDataDir
                  , getIdrisLibDir
                  , getIdrisDocDir
                  , getIdrisCRTSDir
                  , getIdrisJSRTSDir
                  , getIncFlags
                  , getEnvFlags
                  , version
                  ) where

import Data.List.Split

import Control.Applicative ((<$>))
import Data.Maybe (fromMaybe)
import System.FilePath ((</>), addTrailingPathSeparator)
import System.Environment

#ifdef FREESTANDING
import Target_idris
import Paths_idris (version)
#else
import Paths_idris
#endif

getIdrisDataDir :: IO String
getIdrisDataDir = do
  envValue <- lookupEnv "TARGET"
  case envValue of
    Nothing -> do
      ddir <- getDataDir
      return ddir
    Just ddir -> return ddir

overrideIdrisSubDirWith :: String  -- ^ Sub directory in `getDataDir` location.
                        -> String  -- ^ Environment variable to get new location from.
                        -> IO FilePath
overrideIdrisSubDirWith fp envVar = do
  envValue <- lookupEnv envVar
  case envValue of
    Nothing -> do
      ddir <- getIdrisDataDir
      return (ddir </> fp)
    Just ddir -> return ddir

getCC :: IO String
getCC = fromMaybe "gcc" <$> lookupEnv "IDRIS_CC"

getEnvFlags :: IO [String]
getEnvFlags = maybe [] (splitOn " ") <$> lookupEnv "IDRIS_CFLAGS"


#if defined(freebsd_HOST_OS) || defined(dragonfly_HOST_OS)\
    || defined(openbsd_HOST_OS) || defined(netbsd_HOST_OS)
extraLib = ["-L/usr/local/lib"]
extraInclude = ["-I/usr/local/include"]
#else
extraLib = []
extraInclude = []
#endif

#ifdef IDRIS_GMP
gmpLib = ["-lgmp"]
#else
gmpLib = []
#endif

getLibFlags = do dir <- getIdrisCRTSDir
                 return $ ["-L" ++ dir,
                           "-lidris_rts"] ++ extraLib ++ gmpLib ++ ["-lpthread"]

getIdrisLibDir = addTrailingPathSeparator <$> overrideIdrisSubDirWith "libs" "IDRIS_LIBRARY_PATH"

getIdrisDocDir = addTrailingPathSeparator <$> overrideIdrisSubDirWith "docs" "IDRIS_DOC_PATH"

getIdrisJSRTSDir = do
  ddir <- getIdrisDataDir
  return $ addTrailingPathSeparator (ddir </> "jsrts")

getIdrisCRTSDir = do
  ddir <- getIdrisDataDir
  return $ addTrailingPathSeparator (ddir </> "rts")

getIncFlags = do dir <- getIdrisCRTSDir
                 return $ ("-I" ++ dir) : extraInclude
