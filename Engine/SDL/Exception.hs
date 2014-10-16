{-# LANGUAGE DeriveDataTypeable #-}
module Engine.SDL.Exception
  ( 
  -- * Extensible Exceptions
    SDLException(..)
  -- * Utilities
  , err
  ) where

import Control.Exception
import Control.Monad
import Data.Typeable
import Foreign.C
import qualified Graphics.UI.SDL as SDL
import Prelude hiding (init)

-- | This is thrown in the event of an error in the @Engine.SDL@ combinators
newtype SDLException = SDLException String
  deriving (Show, Typeable)

instance Exception SDLException

-- | Treat negative return codes as prompting an error check.
err :: CInt -> IO ()
err e 
  | e < 0 = do
    msg <- SDL.getError >>= peekCString
    SDL.clearError
    when (msg /= "") $ throw $ SDLException msg
  | otherwise = return ()
