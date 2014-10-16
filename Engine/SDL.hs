{-# LANGUAGE DeriveDataTypeable #-}
-- | Start to make SDL binding a bit prettier
--
-- So far this is just Graphics.UI.SDL.Basic minus log handling and hints
-- plus a few other things 
module Engine.SDL 
  ( 
  -- * Extensible Exceptions
    SDLException(..)
  -- * Initialization and Shutdown
  , init, initSubSystem
  , SDL.quit, SDL.quitSubSystem
  , SDL.wasInit
  -- * Versioning
  , Version(..)
  , getVersion
  , getRevision
  , getRevisionNumber
  -- * Video
  , GLattr
  , redSize, greenSize, blueSize, alphaSize, bufferSize, depthSize, stencilSize, accumRedSize, accumGreenSize, accumBlueSize, accumAlphaSize, multiSampleBuffers, multiSampleSamples, contextMajorVersion, contextMinorVersion, contextFlags, contextProfileMask
  , stereo, acceleratedVisual, doubleBuffer, shareWithCurrentContext, framebufferSRGBCapable
  -- * Utilities
  , err
  ) where

import Control.Exception
import Control.Monad
import Data.Functor
import Data.Typeable
import Foreign
import Foreign.C
import Foreign.C.String
import qualified Graphics.UI.SDL as SDL
import Graphics.UI.SDL (GLattr, Version(..))
import Prelude hiding (init)
import Graphics.Rendering.OpenGL.GL.StateVar

data SDLException = SDLException String
  deriving (Show, Typeable)

instance Exception SDLException

-- * Initialization
init :: Word32 -> IO ()
init = SDL.init >=> err

initSubSystem :: Word32 -> IO ()
initSubSystem = SDL.initSubSystem >=> err

-- * Version

getVersion :: IO Version
getVersion = alloca $ \p -> do
  SDL.getVersion p
  peek p

getRevision :: IO String
getRevision = SDL.getRevision >>= peekCString

getRevisionNumber :: IO Int
getRevisionNumber = fromIntegral <$> SDL.getRevisionNumber

-- * Video Attributes as StateVars
  
redSize, greenSize, blueSize, alphaSize, bufferSize, depthSize, stencilSize, accumRedSize, accumGreenSize, accumBlueSize, accumAlphaSize, multiSampleBuffers, multiSampleSamples, contextMajorVersion, contextMinorVersion, contextFlags, contextProfileMask :: StateVar Int

redSize             = attr SDL.glAttrRedSize
greenSize           = attr SDL.glAttrGreenSize
blueSize            = attr SDL.glAttrBlueSize
alphaSize           = attr SDL.glAttrAlphaSize
bufferSize          = attr SDL.glAttrBufferSize
depthSize           = attr SDL.glAttrDepthSize
stencilSize         = attr SDL.glAttrStencilSize
accumRedSize        = attr SDL.glAttrAccumRedSize
accumGreenSize      = attr SDL.glAttrAccumGreenSize
accumBlueSize       = attr SDL.glAttrAccumBlueSize
accumAlphaSize      = attr SDL.glAttrAccumAlphaSize
multiSampleBuffers  = attr SDL.glAttrMultiSampleBuffers
multiSampleSamples  = attr SDL.glAttrMultiSampleSamples
contextMajorVersion = attr SDL.glAttrContextMajorVersion
contextMinorVersion = attr SDL.glAttrContextMinorVersion
contextFlags        = attr SDL.glAttrContextFlags
contextProfileMask  = attr SDL.glAttrContextProfileMask

stereo, acceleratedVisual, doubleBuffer, shareWithCurrentContext, framebufferSRGBCapable :: StateVar Bool
stereo                  = boolAttr SDL.glAttrStereo
acceleratedVisual       = boolAttr SDL.glAttrAcceleratedVisual
doubleBuffer            = boolAttr SDL.glAttrDoubleBuffer
shareWithCurrentContext = boolAttr SDL.glAttrShareWithCurrentContext
framebufferSRGBCapable  = boolAttr SDL.glAttrFramebufferSRGBCapable

-- * Utilities

-- | Build a StateVar from a GLattr
attr :: GLattr -> StateVar Int
attr a = makeStateVar (getAttr a) (setAttr a)

boolAttr :: GLattr -> StateVar Bool
boolAttr a = makeStateVar (toEnum <$> getAttr a) (setAttr a . fromEnum)

getAttr :: GLattr -> IO Int
getAttr a = alloca $ \p -> do
 SDL.glGetAttribute a p >>= err
 fromIntegral <$> peek p

setAttr :: GLattr -> Int -> IO ()
setAttr a i = SDL.glSetAttribute a (fromIntegral i) >>= err

err :: CInt -> IO ()
err e 
  | e < 0 = do
    msg <- SDL.getError >>= peekCString
    SDL.clearError
    throw $ SDLException msg
  | otherwise = return ()