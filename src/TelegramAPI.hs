{-# LANGUAGE OverloadedStrings, DeriveGeneric #-}
module TelegramAPI where

import qualified Data.Text as T
import GHC.Generics hiding (from)
import Data.Aeson
import Control.Monad
import Data.Maybe ( fromMaybe )

-- telegram responce type
data TelegramResponse = Response 
                        { ok :: Bool
                        , result :: [Results]
                        } deriving (Show, Generic)
instance FromJSON TelegramResponse             

-- last 24 hours updates list type
data Results = Results
              { update_id :: Int
              , message :: Message 
          --    , channel_post :: Maybe Message
              } deriving (Show, Generic)
instance FromJSON Results
                                
data Message = Message
               { message_id :: Int
               , from :: Maybe User
               , chat :: Chat
               , date :: Int
               , text :: Maybe T.Text
               , entities :: Maybe [MessageEntity]
               , animation :: Maybe Animation
               , audio :: Maybe Audio
               , document :: Maybe Document
               , photo :: Maybe [PhotoSize]
               , sticker :: Maybe Sticker
               , video :: Maybe Video
               , voice :: Maybe Voice
               , caption :: Maybe T.Text
               , contact :: Maybe Contact
               } deriving (Show, Generic)
instance FromJSON Message            
data MessageEntity = MessageEntity
                     { entityType :: T.Text
                     , offset :: Int
                     , entiityLength :: Int
                     } deriving Show
instance FromJSON MessageEntity  where
    parseJSON (Object v) = 
        MessageEntity   <$> v .: "type"
                        <*> v .: "offset"
                        <*> v .: "length"
                 --       <*> v .: "url"
                 --       <*> v .: "user"
                 --       <*> v .: "language"                      
data PhotoSize = PhotoSize 
            { file_id :: T.Text
            , file_unique_id :: T.Text
            , file_size :: Maybe Int
            , width :: Int
            , height :: Int
            } deriving (Show, Generic)
instance FromJSON PhotoSize         
data User = From 
            { id :: Int
            , is_bot :: Bool
            , first_name :: T.Text
            , last_name :: Maybe T.Text
            , username :: Maybe T.Text
            , language_code :: Maybe T.Text
            } deriving (Show, Generic)
instance FromJSON User             
data Animation = Animation
                 { file_idAn :: T.Text
                 , file_unique_idAn :: T.Text
                 , widthAn :: Int
                 , heightAn :: Int
                 , duration :: Int
                 , thumb :: Maybe PhotoSize
                 , file_nameAn :: Maybe T.Text
                 , mime_type :: Maybe T.Text
                 , file_sizeAn :: Maybe Int
                 } deriving Show
instance FromJSON Animation where
    parseJSON (Object v) = 
        Animation   <$> v .: "file_id"
                    <*> v .: "file_unique_id"
                    <*> v .: "width"
                    <*> v .: "height"
                    <*> v .: "duration"
                    <*> v .: "thumb"
                    <*> v .: "file_name"
                    <*> v .: "mime_type"
                    <*> v .: "file_size" 
data Chat = Chat
            { chat_id :: Int
            , chat_FirstName :: Maybe T.Text
            , chat_LastName :: Maybe T.Text
            , chat_UserName :: Maybe T.Text
            , chat_Type :: T.Text
            } deriving Show         
instance FromJSON Chat where
    parseJSON (Object v) = 
           Chat <$> v .: "id"
                <*> v .: "first_name"
                <*> v .: "last_name"
                <*> v .: "username"
                <*> v .: "type"    
data Audio = Audio 
            { file_idAud :: T.Text
            , file_unique_idAud :: T.Text
            , durationAud :: Int
            } deriving Show
instance FromJSON Audio where
    parseJSON (Object v) = 
        Audio   <$> v .: "file_id"
                <*> v .: "file_unique_id"
                <*> v .: "duration"
data Document = Document
                { file_idDoc :: T.Text
                , file_unique_idDoc :: T.Text
                } deriving Show
instance FromJSON Document where
    parseJSON (Object v) = 
        Document <$> v .: "file_id"
                 <*> v .: "file_unique_id"
data Video = Video
             { file_idVid :: T.Text
             , file_unique_idVid :: T.Text
             , widthVid :: Int
             , heightVid :: Int
             , durationVid :: Int
             } deriving Show
instance FromJSON Video where
    parseJSON (Object v) = 
        Video   <$> v .: "file_id"
                <*> v .: "file_unique_id"
                <*> v .: "width"
                <*> v .: "height"
                <*> v .: "duration" 
data Voice = Voice
             { file_idV :: T.Text
             , file_unique_idV :: T.Text
             , durationV :: Int
             } deriving Show
instance FromJSON Voice where
    parseJSON (Object v) = 
        Voice   <$> v .: "file_id"
                <*> v .: "file_unique_id"
                <*> v .: "duration"
data Sticker = Sticker
               { file_idSt :: T.Text
               , file_unique_idSt :: T.Text
               , widthSt :: Int
               , heightSt :: Int
               , is_animated :: Bool
               } deriving Show
instance FromJSON Sticker where
    parseJSON (Object v) = 
        Sticker <$> v .: "file_id"
                <*> v .: "file_unique_id"
                <*> v .: "width"
                <*> v .: "height"
                <*> v .: "is_animated"
data Contact = Contact
               { phone_number :: T.Text
               , first_nameCon :: T.Text
               , last_nameCon :: Maybe T.Text
               , user_idCon :: Maybe Int
               , vcard :: Maybe T.Text
               } deriving Show
instance FromJSON Contact where
    parseJSON (Object v) =
        Contact <$> v .: "phone_number" 
                <*> v .: "first_name"
                <*> v .: "last_name"
                <*> v .: "user_id"
                <*> v .: "vcard"
                                                                                                                      
printResults :: Maybe [Results] -> IO ()
printResults Nothing = print "error loading data"
printResults (Just results) = do
   forM_ results (print . text . message) 
    