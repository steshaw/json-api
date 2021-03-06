{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{- |
Module representing a JSON-API resource object.

Specification: <http://jsonapi.org/format/#document-resource-objects>
-}
module Network.JSONApi.Identifier
( IdentifierContext (..)
, HasId(..)
, Identifier (..)
, datatype
, ident
, metadata
, new
, existing
, New
, Existing
, ResourceState
-- * Unsafe
, maybeExisting
) where

import Control.Lens.TH
import Data.Aeson (ToJSON, FromJSON, (.=), (.:), (.:?))
import qualified Data.Aeson as AE
import Data.Hashable
import qualified Data.HashMap.Strict as HM
import Data.Maybe (fromMaybe)
import Data.Proxy
import Data.Text (Text)
import qualified GHC.Generics as G
import Network.JSONApi.Meta (Meta(..))
import Prelude hiding (id)

data New
data Existing

type family ResourceState st a where
  ResourceState New a = Proxy a
  ResourceState Existing a = a
  ResourceState (Either New Existing) a = Maybe a

{- |
Identifiers are used to encapsulate the minimum amount of information
to uniquely identify a resource.

This object will be found at multiple levels of the JSON-API structure

Specification: <http://jsonapi.org/format/#document-resource-identifier-objects>
-}
data Identifier st = Identifier
  { _ident :: ResourceState st Text
  , _datatype :: Text
  , _metadata :: Meta
  } deriving (G.Generic)

instance (Show (ResourceState st Text)) => Show (Identifier st) where
  showsPrec n v =
    showString "Identifier {_ident = " .
    showsPrec n (_ident v) .
    showString ", _datatype = " .
    showsPrec n (_datatype v) .
    showString ", _metadata = " .
    showsPrec n (_metadata v) .
    showString "}"

instance (Eq (ResourceState st Text)) => Eq (Identifier st) where
  (==) a b =
    _ident a == _ident b &&
    _datatype a == _datatype b &&
    _metadata a == _metadata b

instance (Hashable (ResourceState st Text)) => Hashable (Identifier st) where
  hashWithSalt s x =
    s `hashWithSalt`
    _ident x `hashWithSalt`
    _datatype x `hashWithSalt`
    _metadata x

instance ToJSON (Identifier Existing) where
  toJSON (Identifier resId resType resMetaData) =
    AE.object $ addOptional ["id" .= resId, "type" .= resType]
    where
      addOptional l =
        if HM.null (fromMeta resMetaData)
          then l
          else (("meta" .= resMetaData) : l)

instance FromJSON (Identifier Existing) where
  parseJSON =
    AE.withObject "resourceIdentifier" $ \v -> do
      id <- v .: "id"
      typ <- v .: "type"
      meta <- v .:? "meta"
      return $ Identifier id typ (fromMaybe mempty meta)

instance ToJSON (Identifier New) where
  toJSON (Identifier Proxy resType resMetaData) =
    AE.object $ addOptional ["id" .= AE.Null, "type" .= resType]
    where
      addOptional l =
        if HM.null (fromMeta resMetaData)
          then l
          else (("meta" .= resMetaData) : l)

instance FromJSON (Identifier New) where
  parseJSON =
    AE.withObject "resourceIdentifier" $ \v -> do
      mid <- v .:? "id"
      case mid of
        Nothing -> pure ()
        Just AE.Null -> pure ()
        Just _ -> fail "'id' provided for a new resource"
      typ <- v .: "type"
      meta <- v .:? "meta"
      return $ Identifier Proxy typ (fromMaybe mempty meta)

instance ToJSON (Identifier (Either New Existing)) where
  toJSON (Identifier id resType resMetaData) =
    AE.object $ addOptional ["id" .= id, "type" .= resType]
    where
      addOptional l =
        if HM.null (fromMeta resMetaData)
          then l
          else (("meta" .= resMetaData) : l)

instance FromJSON (Identifier (Either New Existing)) where
  parseJSON =
    AE.withObject "resourceIdentifier" $ \v -> do
      mid <- v .:? "id"
      typ <- v .: "type"
      meta <- v .:? "meta"
      return $ Identifier mid typ (fromMaybe mempty meta)

{- |
Typeclass indicating how to access metadata for the given datatype.
-}
class IdentifierContext a where
  resourceType :: a -> Text

  resourceMeta :: a -> Meta
  resourceMeta _ = mempty

{- |
Typeclass indicating that the given data type contains a resource id.
-}
class HasId a where
  resourceId :: a -> Text

existing :: (IdentifierContext a, HasId a) => a -> Identifier Existing
existing x = Identifier (resourceId x) (resourceType x) (resourceMeta x)

new :: (IdentifierContext a) => a -> Identifier New
new x = Identifier Proxy (resourceType x) (resourceMeta x)

-- | Slightly unsafe constructor that should go away when a good solution is found
maybeExisting :: (IdentifierContext a) => a -> (a -> Maybe Text) -> Maybe (Identifier Existing)
maybeExisting x f = case f x of
  Nothing -> Nothing
  Just ident -> Just $ Identifier ident (resourceType x) (resourceMeta x)

makeLenses ''Identifier
