{-# LANGUAGE OverloadedStrings #-}
module Request ( buildRequest
               , updatesParametrs
               , updateRequest
               , getUpdate
               , sendMessage
               , prepareMessage
               ) where

import Parser ( getMessageCaptionEntity
              , getMessageCaption
              , getMessageEntity
              , getSendingMethod
              , getMessageContent
              , getMessageChatID
              , makeRepeatMessage
              , SendingMethod
              , ChatID )
import Config ( readToken
              , telegramLimit
              , telegramTimeout
              , defaultKeyboard
              )
import Users (readMapFromFile)  
import TelegramAPI ( message, channel_post, TelegramResponse (result))   
import qualified Data.Text as T
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy.Char8 as LBS (toStrict)         
import Network.HTTP.Simple (addToRequestQueryString, httpLBS, parseRequest_, Request)
import Data.Aeson (encode)
import Network.HTTP.Conduit ( urlEncodedBody )
import Control.Applicative ( Alternative((<|>)) )



type Host = BC.ByteString
type Path = BC.ByteString
type Token = BC.ByteString
type TelRequestBody = BC.ByteString
type TelOffset = Int
type TelLimit = Int
type TelTimeout = Int
type TelAllowedUpdates = [T.Text]
type UpdatesParametrs = BC.ByteString 

botTelegramHost :: Host
botTelegramHost = "https://api.telegram.org" 
botTelegramPath ::Path
botTelegramPath = "/bot"  
telegramToken :: IO Token
telegramToken = readToken

buildRequest :: Host -> Path -> Token -> TelRequestBody
buildRequest host path token = host <> path <> token 

updatesParametrs :: TelLimit -> TelTimeout-> TelOffset -> UpdatesParametrs  -- запрос без TelAllowedUpdates
updatesParametrs telLimit telTimeout telOffset = 
    "?offset=" <> telOffsetBCString <> "&limit=" <> telLimitBCString 
    <> "&timeout=" <> telTimeoutBCString
    where telOffsetBCString = BC.pack . show $ telOffset
          telTimeoutBCString = BC.pack . show $ telTimeout
          telLimitBCString = BC.pack . show $ telLimit

getUpdate :: IO TelOffset -> IO BC.ByteString
getUpdate lastUpdateID = do 
    token <- telegramToken
    updateID <- lastUpdateID
    let body = buildRequest botTelegramHost botTelegramPath token 
    let suffics = updatesParametrs telegramLimit telegramTimeout (updateID + 1)
    let update = body <> "/getUpdates" <> suffics          
    return update 

updateRequest :: BC.ByteString -> TelAllowedUpdates -> Request
updateRequest updRequest allowUpdates = 
    let request1 = parseRequest_ . BC.unpack $ updRequest
    in  urlEncodedBody [("allowed_updates", (LBS.toStrict . encode) allowUpdates)] request1
    

prepareMessage :: ChatID -> SendingMethod -> IO BC.ByteString
prepareMessage chatID method = do
    token <- telegramToken
    let reg = buildRequest botTelegramHost botTelegramPath  
              token
    let request = reg <> method <> "?chat_id=" <> chatID 
    return request

sendMessage :: TelegramResponse -> IO ()
sendMessage decodeUpdate = do 
    if null (result decodeUpdate) 
    then return ()
    else do let telRes = head . result $ decodeUpdate
            let chat = getMessageChatID telRes 
            let cont = getMessageContent $ message telRes <|> channel_post telRes
            let ent = getMessageEntity $ message telRes <|> channel_post telRes
            let cap = getMessageCaption $ message telRes <|> channel_post telRes
            let cap_ent = getMessageCaptionEntity $ message telRes <|> channel_post telRes
            let meth = getSendingMethod $ message telRes <|> channel_post telRes
            request <- fmap (parseRequest_ . BC.unpack) (prepareMessage chat meth)
            if (snd . head $ cont) /= Just BC.empty
            then do 
                let requestWithContent = addToRequestQueryString (cont <> ent <> cap <> cap_ent) request
                httpLBS requestWithContent
                return ()
            else do 
                mapOfUsers <- readMapFromFile "Users.txt"
                let contForRepeat = makeRepeatMessage decodeUpdate mapOfUsers
                let requestWithContent = addToRequestQueryString contForRepeat request
                let requestWithKeyboard = 
                     urlEncodedBody [ ("reply_markup"
                                    , (LBS.toStrict . encode) defaultKeyboard)
                                    ] requestWithContent
                httpLBS requestWithKeyboard
                return ()
           
           

{- data TelegramRequest = TelegramRequest
                       { hostTel :: Host
                       , pathTel :: Path
                       , tokenTel :: Token
                       , getUpd :: Maybe GetUpdates
                       , sendMess :: Maybe SendMessage
                       , sendRhoto :: Maybe SendPhoto
                       , sendAnimation :: Maybe SendAnimation
                       , sendAudio :: Maybe SendAudio 
                       , sendDocument :: Maybe SendDocument
                       , sendVideo :: Maybe SendVideo 
                       , sendVoice :: Maybe SendVoice 
                       , sendSticker :: Maybe SendSticker
                       , sendContact :: Maybe SendContact 
                       } deriving (Show, Generic)
data SendMessage = SendMessage
                   { chat_id :: Int
                   , text :: BC.ByteString
                   , reply_markup :: ReplyKeyboardMarkUp
                   } deriving (Show, Generic)


data ReplyKeyboardMarkUp = ReplyKeyboardMarkUp
                           { keyBoard :: [[KeyboardButton]]
                           , one_time_keyboard :: Bool
                           } deriving (Show, Generic)
                                           
            
data KeyboardButton = KeyboardButton 
                      { textKB :: BC.ByteString
                      } deriving (Show, Generic)
       

data GetUpdates = GetUpdates
                 { offset :: TelOffset
                 , limit :: TelLimit
                 , timeout :: TelTimeout
                 , allowed_updates :: [TelAllowedUpdates]
                 } deriving (Show, Generic)
                    

data SendPhoto = SendPhoto 
                 { photoChat_id :: Int
                 , photo :: BC.ByteString -- file_id
                 , photoCaption :: BC.ByteString
                 } deriving Show 

data SendAnimation = SendAnimation
                     { animationChat_id :: Int
                     , animation :: BC.ByteString
                     , animationCaption :: BC.ByteString
                     } deriving Show
                        
data SendAudio = SendAudio
                 { audioChat_id :: Int
                 , audio :: BC.ByteString
                 , audioCaption :: BC.ByteString
                 } deriving Show
  
data SendContact = SendContact
                   { contactChat_id :: Int
                   , phone_number :: BC.ByteString
                   , contactFirst_name :: BC.ByteString
                   } deriving Show
     
data SendDocument = SendDocument
                    { documentChat_id :: Int
                    , document :: BC.ByteString
                    , documentCaption :: BC.ByteString
                     } deriving Show
 
data SendVideo = SendVideo
                 { videoChat_id :: Int
                 , video :: BC.ByteString
                 , videoCaption :: BC.ByteString
                 } deriving Show
     
data SendVoice = SendVoice
                 { voiceChat_id :: Int
                 , voice :: BC.ByteString
                 , voiceCaption :: BC.ByteString
                 } deriving Show
   
data SendSticker = SendSticker
                   { stickerChat_id :: Int
                   , sticker :: BC.ByteString -- file_id
                   } deriving Show 
-}