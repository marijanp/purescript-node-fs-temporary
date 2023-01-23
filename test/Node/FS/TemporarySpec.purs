module Node.FS.TemporarySpec (spec) where

import Data.Maybe (Maybe(..))
import Effect.Class (liftEffect)
import Prelude
import Test.Spec
import Test.Spec.Assertions (shouldReturn, shouldNotEqual)
import Test.Spec.Assertions.String (shouldStartWith)
import Node.FS.Temporary ((/\), withTempDirectory, withSystemTempDirectory, withTempFile, withSystemTempFile)
import Node.Buffer (fromString, create, toString, size)
import Node.Encoding (Encoding(UTF8))
import Node.FS.Aff (stat, writeTextFile, readTextFile, fdWrite, fdRead)
import Node.FS.Sync (exists)
import Node.FS.Stats (isDirectory, isFile)
import Node.Path (normalize, sep)

spec :: Spec Unit
spec = do
  testWithTempDirectory
  testWithSystemTempDirectory
  testWithTempFile
  testWithSystemTempFile

testWithTempDirectory :: Spec Unit
testWithTempDirectory = do
  let
    targetPath = "."
    template = "test-"
    expectedDirPath = normalize $ targetPath <> sep <> template
  describe "withTempDirectory" do
    around (withTempDirectory targetPath template) do
      it "should create a directory at the given path" \directory -> do
        liftEffect (exists directory) `shouldReturn` true
        (isDirectory <$> stat directory) `shouldReturn` true

      it "should create a directory with the given template" \directory -> do
        directory `shouldStartWith` expectedDirPath

      it "when used multiple times with same parameters, should create two distinct directories" \directory -> do
        withTempDirectory targetPath template \otherDir -> do
          liftEffect (exists otherDir) `shouldReturn` true
          (isDirectory <$> stat otherDir) `shouldReturn` true
          liftEffect (exists directory) `shouldReturn` true
          (isDirectory <$> stat directory) `shouldReturn` true
          otherDir `shouldNotEqual` directory

      it "adding files to the directory should not fail" \directory -> do
        let
          testFilePath = directory <> sep <> "test.txt"
        writeTextFile UTF8 testFilePath "Hello"

    it "should delete the directory and contents after running the action" do
      directory <- withTempDirectory targetPath template $ \directory -> do
        let
          testFilePath = directory <> sep <> "test.txt"
        writeTextFile UTF8 testFilePath "Hello"
        pure directory
      liftEffect (exists directory) `shouldReturn` false
      liftEffect (exists $ directory <> sep <> "test.text") `shouldReturn` false

testWithSystemTempDirectory :: Spec Unit
testWithSystemTempDirectory = do
  around (withSystemTempDirectory "test-") $ do
    describe "withSystemTempDirectory" do
      it "should not fail when the OSs tmpdir is configured" \directory -> do
        (liftEffect <<< exists $ directory) `shouldReturn` true
        (isDirectory <$> stat directory) `shouldReturn` true

testWithTempFile :: Spec Unit
testWithTempFile = do
  let
    targetPath = "."
    template = "test-"
    expectedFilePath = normalize $ targetPath <> sep <> template
    expectedContent = "Hello, my name is"
  describe "withTempFile" do
    around (withTempFile targetPath template) $ do
      it "should create a file at the given path" \(filePath /\ _) -> do
        (liftEffect <<< exists $ filePath) `shouldReturn` true
        (isFile <$> stat filePath) `shouldReturn` true

      it "should create a file with the given template" \(filePath /\ _) -> do
        filePath `shouldStartWith` expectedFilePath

      it "when used multiple times with the same parameters, should create two distinct files" \(filePath /\ _) -> do
        withTempFile targetPath template \(otherFilePath /\ _) -> do
          (liftEffect <<< exists $ otherFilePath) `shouldReturn` true
          (isFile <$> stat otherFilePath) `shouldReturn` true
          (liftEffect <<< exists $ filePath) `shouldReturn` true
          (isFile <$> stat filePath) `shouldReturn` true
          otherFilePath `shouldNotEqual` filePath

      it "reading and writing the file using the file path should not fail" \(filePath /\ _) -> do
        writeTextFile UTF8 filePath expectedContent
        readTextFile UTF8 filePath `shouldReturn` expectedContent

      it "reading and writing the file using the file descriptor should not fail" \(_ /\ fileDescriptor) -> do
        let
          filePosition = Just 0
          offset = 0
        writeBuffer <- liftEffect $ fromString expectedContent UTF8
        bufferSize <- liftEffect $ size writeBuffer
        void $ fdWrite fileDescriptor writeBuffer offset bufferSize filePosition
        readBuffer <- liftEffect $ create bufferSize
        void $ fdRead fileDescriptor readBuffer offset bufferSize filePosition
        (liftEffect $ toString UTF8 readBuffer) `shouldReturn` expectedContent

    it "should delete the file after running the action" do
      filePath <- withTempFile targetPath template \(filePath /\ _) -> do
        writeTextFile UTF8 filePath expectedContent
        pure filePath
      (liftEffect <<< exists $ filePath) `shouldReturn` false

testWithSystemTempFile :: Spec Unit
testWithSystemTempFile = do
  around (withSystemTempFile "test-") $ do
    describe "withSystemTempFile" do
      it "should not fail when the OSs tmpdir is configured" \(filePath /\ _) -> do
        (liftEffect <<< exists $ filePath) `shouldReturn` true
        (isFile <$> stat filePath) `shouldReturn` true
