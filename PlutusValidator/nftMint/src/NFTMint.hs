{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}

{-# OPTIONS_GHC -fno-warn-unused-imports #-}

module NFTMint where

import           PlutusTx             (Data (..))
import qualified PlutusTx
import           PlutusTx.Prelude     hiding (Semigroup(..), unless)
import           Ledger               hiding (singleton)
import qualified Ledger.Typed.Scripts as Scripts
import           Prelude              (IO, Semigroup (..), Show (..), String)


-- OnChain Validator (Plutus Script Definition)

data ContractParams = ContractParams
    { opsowner :: PaymentPubKeyHash
    } deriving Show

PlutusTx.makeLift ''ContractParams


data NFTMintDatum = NFTMNT
                   { datumValType :: Integer
                   } deriving (Show)

PlutusTx.makeIsDataIndexed ''NFTMintDatum [('NFTMNT,0)]


data NFTMintRedeemer = NFTRDMR
                   { redeemerValType :: Integer
                   } deriving (Show)

PlutusTx.makeIsDataIndexed ''NFTMintRedeemer [('NFTRDMR,0)]


{-# INLINABLE mkValidator #-}
mkValidator :: ContractParams -> NFTMintDatum -> NFTMintRedeemer -> ScriptContext -> Bool
mkValidator p datum redeemer ctx = traceIfFalse "Owner SignKeyHash is Invalid or Missing" signedByOwner &&
                            traceIfFalse "Wrong Datum!"    ( datumValType    datum    == 28556000 )     &&
                            traceIfFalse "Wrong Redeemer!" ( redeemerValType redeemer == 28556000 )
  where
    info :: TxInfo
    info =  scriptContextTxInfo ctx

    signedByOwner :: Bool
    signedByOwner =  txSignedBy info $ unPaymentPubKeyHash $ opsowner p


data NFTMint
instance Scripts.ValidatorTypes NFTMint where
    type instance DatumType    NFTMint = NFTMintDatum
    type instance RedeemerType NFTMint = NFTMintRedeemer


typedValidator :: ContractParams -> Scripts.TypedValidator NFTMint
typedValidator p = Scripts.mkTypedValidator @NFTMint
    ($$(PlutusTx.compile [|| mkValidator ||]) `PlutusTx.applyCode` PlutusTx.liftCode p)
     $$(PlutusTx.compile [|| wrap ||])
       where
         wrap = Scripts.wrapValidator @NFTMintDatum @NFTMintRedeemer


validator :: ContractParams -> Validator
validator =  Scripts.validatorScript . typedValidator
