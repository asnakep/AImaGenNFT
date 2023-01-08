#!/run/current-system/sw/bin/bash

### Emurgo Academy CDP Project     ##
### Cardano NFT Vending Machine    ##
### Emanuele Concotelli 06/01/2023 ##

while true
do

### Hide Cursor + Reset Cursor on CTRL+C
tput civis
trap 'tput reset; exit 1' 2

### Script Variables
whib=`printf "\033[1;37m"`
greb=`printf "\033[1;32m"`

ada=$(printf "\U20B3")
preview='--testnet-magic 2'
BlockFrostID=previewl6OAJyAGhoXnLqC7gqqRRrQ9kpfg1LOK

jsonDir=.jsonFiles
txsDir=.txsDir

nftPrice="28556000"

vendingMachineAddr=$(cat ../CryptoMaterial/addresses/operations.addr)
vendingMachineSignKey='../CryptoMaterial/addresses/operations.skey'

mintingAddr=$(cat ../CryptoMaterial/addresses/nft_minting.addr)
mintingSignKey='../CryptoMaterial/addresses/nft_minting.skey'
mintingScript='../CryptoMaterial/addresses/mintNFT.script'
mintingPolicyID=3bf85b8529b2f56ec2d62a1e894079665bcb59e64787efc30b946f23

scriptAddr=$(cat ../CryptoMaterial/plutusValidator/nftMint/scriptAddrNft.addr)
minterSignHash=fc7a144948d29161b610ae615a66597876d48b61e41006444a738804
plutusScript='../CryptoMaterial/plutusValidator/nftMint/nftMint.plutus'
datum='../CryptoMaterial/plutusValidator/nftMint/nftMintDatum.json'
redeemer='../CryptoMaterial/plutusValidator/nftMint/nftMintRedeemer.json'


### Payments on vendingMachineAddr (Handle$workDir/utxos Queue)

### Get vendingMachineAddr Address$workDir/utxos List
UTxOsUrl=https://cardano-preview.blockfrost.io/api/v0/addresses/$vendingMachineAddr/utxos
curl -s $UTxOsUrl -X GET -H "project_id: $BlockFrostID" | jq -r '.[] | .amount[].quantity, .tx_hash, .tx_index' > .utxos

### Get received Value (lovelace and ADA format)
recLovelaces=$(sed -n 1,3p .utxos | sed -n 1p)
adas=$(sed -n 1,3p .utxos | sed -n 1p | rev | sed 's/./&,/6' | rev)


### On Empty Operations Address UTxOs
if [[ ! -s .utxos  ]]; then

sleep 0.1
tput clear
echo
echo
echo $greb"AImaGen NFT Vending Machine Address is empty."
echo
echo $greb"Waiting for Payments..."
echo
sleep 0.1


### On Right Amount Received to vendingMachineAddr Address
elif [[ "$nftPrice" == "$recLovelaces"  ]]; then

tput clear

echo
echo $whib"Received: $greb$ada" $adas
echo
echo $whib"Lovelaces:" $greb$recLovelaces

recTxId=$(sed -n 1,3p .utxos | sed -n 2p)

TxUrl=https://cardano-preview.blockfrost.io/api/v0/txs/$recTxId/utxos

buyerAddr=$(curl -s $TxUrl -X GET -H "project_id: $BlockFrostID" | jq -r .inputs[].address)

echo
echo $whib"From Address:" $greb$buyerAddr
echo

TxID=$(sed -n 1,3p .utxos | sed -n 2p)
TxIX=$(sed -n 1,3p .utxos | sed -n 3p)

UTxO=$TxID"#"$TxIX

echo $whib"Price to Mint CNFT is Right!"


### Sending NFT Funds to Contract Script Address
echo
echo $whib"Sending Funds to Contract Address."

### Build Raw Tx
cardano-cli transaction build-raw --babbage-era --tx-in $UTxO --tx-out $scriptAddr+0 --tx-out $vendingMachineAddr+0 \
--tx-out-datum-hash-file $datum --fee 0 --out-file $txsDir/giveToScript.txbody

### Calculate Tx Fees
txfees=$(cardano-cli transaction calculate-min-fee --tx-body-file $txsDir/giveToScript.txbody --tx-in-count 1 --tx-out-count 2 \
--witness-count 1 $preview --protocol-params-file $jsonDir/protocol-parameters.json | awk '{print $1}')

### Build Tx
cardano-cli transaction build-raw --babbage-era --tx-in $UTxO --tx-out $scriptAddr+$(expr $recLovelaces - $txfees) \
--tx-out-datum-hash-file $datum --fee $txfees --out-file $txsDir/giveToScript.txbody

### Sign Tx
cardano-cli transaction sign $preview --signing-key-file $vendingMachineSignKey --tx-body-file $txsDir/giveToScript.txbody \
--out-file $txsDir/giveToScript.signed

### Submit Tx via blockfrost API
xxd -r -p <<< $(jq .cborHex $txsDir/giveToScript.signed) > $txsDir/giveToScriptBinary.signed

echo
echo $whib"Transaction Submitted."
echo
echo $greb"TxID Hash:"$whib
echo
curl "https://cardano-preview.blockfrost.io/api/v0/tx/submit" -X POST -H "Content-Type: application/cbor" \
-H "project_id: $BlockFrostID" --data-binary @./$txsDir/giveToScriptBinary.signed
echo
echo
echo $greb"Waiting 1 Minute for BlockFrost API Db Syncing..."
echo

### Archive TXs Files
for txFiles in $(ls -l $txsDir/giveToScript* | awk {'print $9'})
do
mv $txFiles $txFiles.$(date '+%d%m%Y'-'%H'.'%M')
done
mv $txsDir/giveToScript* $txsDir/Archived/givenToScript ; chmod 400 $txsDir/Archived/givenToScript/*

sleep 60


### Grabbing NFT Mint Funds from Contract Script Address
tput clear
echo
echo $whib"Grabbing CNFT Mint Funds from Contract Address."
echo

### NFT Mint Owner Grab Funds from Script Address for NFT Minting
scriptUTxOsUrl=https://cardano-preview.blockfrost.io/api/v0/addresses/$scriptAddr/utxos
curl -s $scriptUTxOsUrl -X GET -H "project_id: $BlockFrostID" | jq -r '.[] | .tx_hash, .tx_index' > .scriptUtxos

TxID1=$(sed -n 1,1p .scriptUtxos | sed -n 1p)
TxIX1=$(sed -n 1,2p .scriptUtxos | sed -n 2p)

scriptUTxO=$TxID1"#"$TxIX1

### Getting Collateral for Grab Tx
collateralUTxOsUrl=https://cardano-preview.blockfrost.io/api/v0/addresses/$mintingAddr/utxos
curl -s $collateralUTxOsUrl -X GET -H "project_id: $BlockFrostID" | jq -r '.[] | .tx_hash, .tx_index' > .collateralUtxos

TxID2=$(sed -n 1,1p .collateralUtxos | sed -n 1p)
TxIX2=$(sed -n 1,2p .collateralUtxos | sed -n 2p)

collateralUTxO=$TxID2"#"$TxIX2

### Build Grab Tx
cardano-cli transaction build --babbage-era $preview --change-address $mintingAddr --tx-in $scriptUTxO \
--tx-in-script-file $plutusScript --tx-in-datum-file $datum --tx-in-redeemer-file $redeemer \
--tx-in-collateral $collateralUTxO --required-signer-hash $minterSignHash --protocol-params-file $jsonDir/protocol-parameters.json \
--out-file $txsDir/grabFromScript.txbody

### Sign Tx
cardano-cli transaction sign $preview --signing-key-file $mintingSignKey --tx-body-file $txsDir/grabFromScript.txbody \
--out-file $txsDir/grabFromScript.signed

### Submit Tx via blockfrost API
xxd -r -p <<< $(jq .cborHex $txsDir/grabFromScript.signed) > $txsDir/grabFromScriptBinary.signed

echo
echo $whib"Transaction Submitted."
echo
echo $greb"TxID Hash:"$whib
echo
curl "https://cardano-preview.blockfrost.io/api/v0/tx/submit" -X POST -H "Content-Type: application/cbor" \
-H "project_id: $BlockFrostID" --data-binary @./$txsDir/grabFromScriptBinary.signed
echo
echo
echo $greb"Waiting 1 Minute for BlockFrost API Db Syncing..."
echo

### Archive TXs Files
for txFiles in $(ls -l $txsDir/grabFromScript* | awk {'print $9'})
do
mv $txFiles $txFiles.$(date '+%d%m%Y'-'%H'.'%M')
done
mv $txsDir/grabFromScript* $txsDir/Archived/grabbedFromScript ; chmod 400 $txsDir/Archived/grabbedFromScript/*

sleep 60


### Mint NFT
tput clear
echo
echo $whib"Minting one AImaGen CNFT."
echo


### Generate Image, Pin to IPFS and Get IPFS Url
rm out-0.png 2>/dev/null

python3 ../AImaGen/StableDiffusion/ImaGen.py

../AImaGen/IPFS/pin_to_ipfs.sh out-0.png > .ipfsHash

ipfsUrl=ipfs:
ipfsHash=$(sed 's/\/ipfs/\//' .ipfsHash)
IPFS_URL=$ipfsUrl$ipfsHash

### Token Definition
humanTokenName="AImaGeN@$(date +%s)"
tokenName=$(echo -n $humanTokenName | xxd -ps | tr -d '\n')
tokenNum="1"

### Write NFT Metadata
cat << EOF > $jsonDir/nft_metadata.json
{
  "721": {
          "$mintingPolicyID": {
          "$humanTokenName": {
          "description": "AImaGeN - Fully AI Generated CNFT",
          "image": "$IPFS_URL"
      }
    }
  }
}
EOF


### Build NFT Minting Tx
mintingAddrBalance=$(cardano-cli query utxo --address $mintingAddr $preview  | sed '1,2d' | awk '{print $3}' | xargs | sed 's/ / + /g' | xargs expr +)

mintTxUTxOs=$(cardano-cli query utxo --address $mintingAddr $preview | sed '1,2d' | awk '{print $1"#"$2}' | sed 's/^/--tx-in /g')

minUTxo=1500000

cardano-cli transaction build --babbage-era $preview $mintTxUTxOs --tx-out $mintingAddr+$minUTxo+"$tokenNum $mintingPolicyID.$tokenName" \
--change-address $mintingAddr --mint="$tokenNum $mintingPolicyID.$tokenName" --minting-script-file $mintingScript \
--metadata-json-file $jsonDir/nft_metadata.json --witness-override 2 --out-file $txsDir/mintNFT.txbody

### Sign TX ###
cardano-cli transaction sign $preview --signing-key-file $mintingSignKey --tx-body-file $txsDir/mintNFT.txbody \
--out-file $txsDir/mintNFT.signed

### Submit Tx via blockfrost API
xxd -r -p <<< $(jq .cborHex $txsDir/mintNFT.signed) > $txsDir/mintNFTBinary.signed

echo
echo $whib"Transaction Submitted."
echo
echo $greb"TxID Hash:"$whib
echo
curl "https://cardano-preview.blockfrost.io/api/v0/tx/submit" -X POST -H "Content-Type: application/cbor" \
-H "project_id: $BlockFrostID" --data-binary @./$txsDir/mintNFTBinary.signed
echo
echo
echo $greb"Waiting 1 Minute for BlockFrost API Db Syncing..."
echo

### Archive TXs Files
for txFiles in $(ls -l $txsDir/mintNFT* | awk {'print $9'})
do
mv $txFiles $txFiles.$(date '+%d%m%Y'-'%H'.'%M')
done
mv $txsDir/mintNFT* $txsDir/Archived/mintingTxs ; chmod 400 $txsDir/Archived/mintingTxs/*

sleep 60


### Build TX Send NFT to the Buyer
tput clear
echo
echo $whib"Sending $humanTokenName CNFT to Buyer."


mintingAddrBalance=$(cardano-cli query utxo --address $mintingAddr $preview  | sed '1,2d' | awk '{print $3}' | xargs | sed 's/ / + /g' | xargs expr +)

UTXOs=$(cardano-cli query utxo --address $mintingAddr $preview | sed '1,2d' | awk '{print $1"#"$2}' | sed 's/^/--tx-in /g')

cardano-cli transaction build-raw $UTXOs --tx-out $mintingAddr+0+"0 $mintingPolicyID.$tokenName" \
--tx-out $buyerAddr+0+"1 $mintingPolicyID.$tokenName" --fee 0 --out-file $txsDir/send_nft.txbody

TxInCount=$(cardano-cli query utxo --address $mintingAddr $preview  | sed '1,2d' | wc -l)

txFees=$(cardano-cli transaction calculate-min-fee --tx-body-file $txsDir/send_nft.txbody --tx-in-count $TxInCount --tx-out-count 2 \
--witness-count 1 $preview --protocol-params-file $jsonDir/protocol-parameters.json | awk '{print $1}')

TxOut=$(expr $mintingAddrBalance - $minUTxo - $txFees)

cardano-cli transaction build-raw $UTXOs --tx-out $mintingAddr+$TxOut+"0 $mintingPolicyID.$tokenName" \
--tx-out $buyerAddr+$minUTxo+"1 $mintingPolicyID.$tokenName" --fee $txFees --out-file $txsDir/send_nft.txbody

cardano-cli transaction sign --tx-body-file $txsDir/send_nft.txbody --signing-key-file $mintingSignKey \
$preview --out-file $txsDir/send_nft.signed

### Submit Tx via blockfrost API
xxd -r -p <<< $(jq .cborHex $txsDir/send_nft.signed) > $txsDir/send_nftBinary.signed

echo
echo $whib"Transaction Submitted."
echo
echo $greb"TxID Hash:"$whib
echo
curl "https://cardano-preview.blockfrost.io/api/v0/tx/submit" -X POST -H "Content-Type: application/cbor" \
-H "project_id: $BlockFrostID" --data-binary @./$txsDir/send_nftBinary.signed
echo
echo
echo $greb"Waiting 1 Minute for BlockFrost API Db Syncing..."
echo

### Archive TXs Files
for txFiles in $(ls -l $txsDir/send_nft* | awk {'print $9'})
do
mv $txFiles $txFiles.$(date '+%d%m%Y'-'%H'.'%M')
done
mv $txsDir/send_nft* $txsDir/Archived/sentNFTs ; chmod 400 $txsDir/Archived/sentNFTs/*

sleep 60


### On Wrong Amount Received to vendingMachineAddr Address
else

tput clear

echo
echo $whib"Received: $greb$ada" $adas
echo
echo $whib"Lovelaces:" $greb$recLovelaces

recTxId=$(sed -n 1,3p .utxos | sed -n 2p)

TxUrl=https://cardano-preview.blockfrost.io/api/v0/txs/$recTxId/utxos

buyerAddr=$(curl -s $TxUrl -X GET -H "project_id: $BlockFrostID" | jq -r .inputs[].address)

echo
echo $whib"From Address:" $greb$buyerAddr
echo

TxID=$(sed -n 1,3p .utxos | sed -n 2p)
TxIX=$(sed -n 1,3p .utxos | sed -n 3p)

UTxO=$TxID"#"$TxIX

echo $whib"Sending Back Wrong $ada Amount to the Buyer"


### Give ADA Back to Payer (Empty UTxOs in sequential way, firstTolast)

### Write message for tx metadata
cat << EOF > $jsonDir/sendBackMessage.json
{
  "0": { "string":"Returned Wrong Received Amount of $adas $ada -tx Fees" }
}
EOF

### Build Raw Tx
cardano-cli transaction build-raw --babbage-era --tx-in $UTxO --tx-out $buyerAddr+0 --tx-out $vendingMachineAddr+0 \
--metadata-json-file $jsonDir/sendBackMessage.json --fee 0 --out-file $txsDir/sendBack.txbody

### Calculate Tx Fees
txfees=$(cardano-cli transaction calculate-min-fee --tx-body-file $txsDir/sendBack.txbody --tx-in-count 1 --tx-out-count 2 \
--witness-count 1 $preview --protocol-params-file $jsonDir/protocol-parameters.json | awk '{print $1}')

### Build Tx
cardano-cli transaction build-raw --babbage-era --tx-in $UTxO --tx-out $buyerAddr+$(expr $recLovelaces - $txfees) \
--metadata-json-file $jsonDir/sendBackMessage.json --fee $txfees --out-file $txsDir/sendBack.txbody

### Sign Tx
cardano-cli transaction sign $preview --signing-key-file $vendingMachineSignKey --tx-body-file $txsDir/sendBack.txbody \
--out-file $txsDir/sendBack.signed

### Submit Tx via blockfrost API
xxd -r -p <<< $(jq .cborHex $txsDir/sendBack.signed) > $txsDir/sendBackBinary.signed

echo
echo $whib"Transaction Submitted."
echo
echo $greb"TxID Hash:"$whib
echo
curl "https://cardano-preview.blockfrost.io/api/v0/tx/submit" -X POST -H "Content-Type: application/cbor" \
-H "project_id: $BlockFrostID" --data-binary @./$txsDir/sendBackBinary.signed
echo
echo
echo $greb"Waiting 1 Minute for BlockFrost API Db Syncing..."
echo

### Archive TXs Files
for txFiles in $(ls -l $txsDir/sendBack* | awk {'print $9'})
do
mv $txFiles $txFiles.$(date '+%d%m%Y'-'%H'.'%M')
done
mv $txsDir/sendBack* $txsDir/Archived/Returned ; chmod 400 $txsDir/Archived/Returned/*

sleep 60

tput clear

fi

done
