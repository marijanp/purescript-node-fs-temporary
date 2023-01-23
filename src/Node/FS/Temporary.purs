module Node.FS.Temporary
  ( withSystemTempDirectory
  , withTempDirectory
  , withSystemTempFile
  , withTempFile
  , module Data.Tuple.Nested
  ) where

import Prelude
import Data.Int (floor)
import Data.Tuple (Tuple)
import Data.Tuple.Nested ((/\))
import Data.Maybe (Maybe(Nothing))
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Random (random)
import Node.Path (FilePath, normalize, sep)
import Node.FS (FileDescriptor, FileFlags(W_PLUS))
import Node.FS.Sync (exists)
import Node.FS.Aff (mkdir, rm', fdOpen, fdClose)
import Node.OS (tmpdir)

-- | Runs an action with a new temporary directory named after the template
-- | inside systems standard temporary directory.
-- |
-- | Behaves like `withTempDirectory`, but uses the directory returned by `Node.OS.tmpdir`.
withSystemTempDirectory :: forall a. String -> (FilePath -> Aff a) -> Aff a
withSystemTempDirectory template action =
  liftEffect tmpdir >>=
    \tmpDir -> withTempDirectory tmpDir template action

-- | Runs an action with a new temporary directory named after the template inside the given directory.
-- | After running the action the temporary directory is deleted.
-- |
-- |`withTempDirectory "test" "test-" \tmpDir -> do ...`
-- |
-- |The `tmpDir` will be a new subdirectory of the given directory, i.e. `tmpDir == test/test-0`.
withTempDirectory :: forall a. FilePath -> String -> (FilePath -> Aff a) -> Aff a
withTempDirectory targetDir template =
  bracket
    (createTempDirectory targetDir template)
    (flip rm' { force: true, maxRetries: 5, recursive: true, retryDelay: 100 })

createTempDirectory :: FilePath -> String -> Aff FilePath
createTempDirectory dir template = do
  x <- floor <<< (_ * 100.0) <$> liftEffect random
  tempName <- getTempName dir template x
  mkdir tempName
  pure tempName

getTempName :: FilePath -> String -> Int -> Aff FilePath
getTempName dir template x = do
  let dirpath = normalize $ dir <> sep <> template <> show x
  liftEffect (exists dirpath) >>= case _ of
    true -> getTempName dir template (x + 1)
    false -> pure dirpath

withSystemTempFile :: forall a. String -> (Tuple FilePath FileDescriptor -> Aff a) -> Aff a
withSystemTempFile template action =
  liftEffect tmpdir >>=
    \tmpDir -> withTempFile tmpDir template action

-- | Runs an action with a new temporary file named after the template inside the given directory.
-- | After running the action the temporary file is deleted.
-- |
-- |`withTempFile "test" "test-" \(filePath /\ fileDescriptor) -> do ...`
-- |
-- |The `filePath` will point to a file inside the given directory, i.e. `filePath == test/test-0`.
withTempFile :: forall a. FilePath -> String -> (Tuple FilePath FileDescriptor -> Aff a) -> Aff a
withTempFile tmpDir template = do
  bracket
    (openTempFile tmpDir template)
    ( \(filePath /\ fileDescriptor) -> do
        fdClose fileDescriptor
        flip rm' { force: true, maxRetries: 5, recursive: false, retryDelay: 100 } filePath
    )

-- | Runs an action with a new temporary file named after the template
-- | inside systems standard temporary directory.
-- |
-- | Behaves like `withTempFile`, but uses the directory returned by `Node.OS.tmpdir`.
openTempFile :: FilePath -> String -> Aff (Tuple FilePath FileDescriptor)
openTempFile tmpDir template = do
  x <- floor <<< (_ * 100.0) <$> liftEffect random
  tempFilePath <- getTempName tmpDir template x
  tempFileDescriptor <- fdOpen tempFilePath W_PLUS Nothing
  pure (tempFilePath /\ tempFileDescriptor)

