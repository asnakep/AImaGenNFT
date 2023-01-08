#!/run/current-system/sw/bin/bash

### ipfs-upload-client is get via nix-env -iA nixos.ipfs-upload-client

InfuraProjID=
InfuraApiKey=
URL="https://ipfs.infura.io:5001"

ipfs-upload-client --id $InfuraProjID --secret $InfuraApiKey  --url $URL --pin $1

