{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

module NFTMintDeploy
    
    ( writeJSON
    , writeValidator
    , writeDatum
    , writeRedeemer
    , writeNFTMintValidator
    ) where

import           Cardano.Api
import           Cardano.Api.Shelley   (PlutusScript (..))
import           Codec.Serialise       (serialise)
import           Data.Aeson            (encode)
import qualified Data.ByteString.Lazy  as LBS
import qualified Data.ByteString.Short as SBS
import           PlutusTx              (Data (..))
import qualified PlutusTx
import qualified Ledger

import           NFTMint

dataToScriptData :: Data -> ScriptData
dataToScriptData (Constr n xs) = ScriptDataConstructor n $ dataToScriptData <$> xs
dataToScriptData (Map xs)      = ScriptDataMap [(dataToScriptData x, dataToScriptData y) | (x, y) <- xs]
dataToScriptData (List xs)     = ScriptDataList $ dataToScriptData <$> xs
dataToScriptData (I n)         = ScriptDataNumber n
dataToScriptData (B bs)        = ScriptDataBytes bs

writeJSON :: PlutusTx.ToData a => FilePath -> a -> IO ()
writeJSON file = LBS.writeFile file . encode . scriptDataToJson ScriptDataJsonDetailedSchema . dataToScriptData . PlutusTx.toData

writeValidator :: FilePath -> Ledger.Validator -> IO (Either (FileError ()) ())
writeValidator file = writeFileTextEnvelope @(PlutusScript PlutusScriptV1) file Nothing . PlutusScriptSerialised . SBS.toShort . LBS.toStrict . serialise . Ledger.unValidatorScript

writeDatum :: IO ()
writeDatum = writeJSON "plutusScripts/nftMintDatum.json" (NFTMNT 28556000)

writeRedeemer :: IO ()
writeRedeemer = writeJSON "plutusScripts/nftMintRedeemer.json" (NFTRDMR 28556000)

writeNFTMintValidator :: IO (Either (FileError ()) ())
writeNFTMintValidator = writeValidator "plutusScripts/nftMint.plutus" $ validator $ ContractParams
    { opsowner = Ledger.PaymentPubKeyHash "fc7a144948d29161b610ae615a66597876d48b61e41006444a738804"
    }

