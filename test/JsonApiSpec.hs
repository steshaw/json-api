{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module JsonApiSpec where

import qualified Data.Aeson as AE
import qualified Data.ByteString.Lazy.Char8 as BS
import Data.Maybe (isJust, fromJust)
import Data.Text (Text, pack)
import GHC.Generics
import JsonApi
import Test.Hspec

data TestResourceObject =
  TestResourceObject { myId :: Int
                     , myName :: Text
                     , myAge :: Int
                     , myFavoriteFood :: Text
                     } deriving (Show, Generic)

data TestMetaObject =
  TestMetaObject { totalPages :: Int
                 , isSuperFun :: Bool
                 } deriving (Show, Generic)

instance AE.ToJSON TestResourceObject
instance AE.FromJSON TestResourceObject

instance AE.ToJSON TestMetaObject
instance AE.FromJSON TestMetaObject

instance ToResourceObject TestResourceObject where
  toResource a =
    ResourceObject
      (ResourceId . pack . show . myId $ a)
      (ResourceType "TestResourceObject")
      a

testObject :: TestResourceObject
testObject = TestResourceObject 1 "Fred Armisen" 49 "Pizza"

testMetaObj :: TestMetaObject
testMetaObj = TestMetaObject 3 True

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "JSON serialization" $ do
    it "can be encoded and decoded from JSON" $ do
      let jsonApiObj = JsonApi (toResource testObject) (Just testMetaObj)
      let encodedJson = BS.unpack . AE.encode $ jsonApiObj
      let decodedJson = AE.decode (BS.pack encodedJson) :: Maybe (JsonApi TestResourceObject (Maybe TestMetaObject))
      putStrLn encodedJson
      putStrLn $ show . fromJust $ decodedJson
      (isJust decodedJson) `shouldBe` True

    it "allows an optional top-level meta object" $ do
      let jsonApiObj = JsonApi (toResource testObject) metaObj
      let encodedJson = BS.unpack . AE.encode $ jsonApiObj
      let decodedJson = AE.decode (BS.pack encodedJson) :: Maybe (JsonApi TestResourceObject (Maybe TestMetaObject))
      putStrLn encodedJson
      putStrLn $ show . fromJust $ decodedJson
      (isJust decodedJson) `shouldBe` True
      where
        metaObj :: Maybe TestMetaObject
        metaObj = Nothing


