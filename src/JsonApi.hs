{-# LANGUAGE OverloadedStrings #-}

module JsonApi
( JsonApi (..)
, RO.ResourceId (..)
, RO.ResourceObject (..)
, RO.ResourceType (..)
, RO.ToResourceObject (..)
, L.Links
, L.toLinks
) where

import           Control.Monad (mzero)
import           Data.Aeson (ToJSON, FromJSON, (.=), (.:), (.:?))
import qualified Data.Aeson as AE
import           Link as L
import           ResourceObject (ResourceObject)
import qualified ResourceObject as RO

data JsonApi a b =
  JsonApi (ResourceObject a) (Maybe Links) (Maybe b)
    deriving (Show, Eq, Ord)

instance (ToJSON a, ToJSON b) => ToJSON (JsonApi a b) where
  toJSON (JsonApi res links meta) =
    AE.object [ "data"  .= res
              , "links" .= links
              , "meta"  .= meta
              ]

instance (FromJSON a, FromJSON b) => FromJSON (JsonApi a b) where
  parseJSON (AE.Object v) =
    JsonApi
      <$> v .: "data"
      <*> v .:? "links"
      <*> v .:? "meta"
  parseJSON _ = mzero
