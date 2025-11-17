# Using <code>cryptoki-bridge</code> with OpenSSL
It is assumed you have created a MeeSign signing group with some clients.

## Get your MeeSign CA certificate
Copy the MeeSign CA certificate to `ca-cert.pem`.

You can download the certificate from the [official MeeSign website](https://meesign.crocs.fi.muni.cz/meesign-ca-cert.pem). If you have a local build of MeeSign server, the corresponding file is placed in `keys/meesign-ca-cert.pem`.

## Build and start the demo container
Build the docker image:
```sh
docker build -t meesign-openssl-demo .
```

MeeSign server binds to port 1337 on `localhost`. You will need to run the demo container in the `host` network for it to see MeeSign server. Open a bash shell in the container using this command:
```sh
docker run -it --network=host --rm meesign-openssl-demo
```

<details>

<summary>I don't want to run the demo on the <code>host</code> network</summary>

Assuming you are running MeeSign server using docker compose, you want to run the demo on the `meesign-network` network.

You will need to modify the `compose.deploy.yaml` file in MeeSign server and add an alias for `meesign-server` in `meesign-network`. Patch it using `alias-network.patch`:
```sh
patch path/to/compose.deploy.yaml < alias-network.patch
```

You can then run the demo using this command:
```sh
docker run -it --network=meesign-network --rm meesign-openssl-demo
```

</details>

## Get the URI of your public and private keys
A signing group defines an abstract keypair. Each key has its URI. To use MeeSign through OpenSSL, a key's URI must be provided. The URI only needs the information necessary to uniquely identify a key. If you have only one group in MeeSign, you should be able to use a URI like `pkcs11:type=<private|public>`, where `private` and `public` specify the key type.

<details>

<summary>Getting the URI using <code>pkcs11-tool</code></summary>

If you're unsure about the URI of your key, you can use `pkcs11-tool` to list all keys:
```sh
pkcs11-tool --module ./libcryptoki_bridge.so -O 2>/dev/null
```
The output might look something like this:
```
Private Key Object; EC
  label:      g
  ID:         0431a9ab3004b4b9
  Usage:      sign
  Access:     none
  Allowed mechanisms: ECDSA
  uri:        pkcs11:model=;manufacturer=;serial=;token=Meesign%3a%20g;id=%0431a9ab3004b4b9;object=g;type=private
Public Key Object; EC  EC_POINT 256 bits
  EC_POINT:   04410431a9ab3004b4b98aa0ce56d52bc558a67d9b95dbe2c5d2a8b87d55ae5dffcfa63cbb8988a762e7284a11c79887c81fee674345f388baf4a1e78366a666317d44
  EC_PARAMS:  06082a8648ce3d030107 (OID 1.2.840.10045.3.1.7)
  label:      g
  ID:         0431a9ab3004b4b9
  Usage:      none
  Access:     none
  uri:        pkcs11:model=;manufacturer=;serial=;token=Meesign%3a%20g;id=%0431a9ab3004b4b9;object=g;type=public
```

Apart from the `id` part, you can simply copy and paste the `uri` field from the output.

OpenSSL does not parse the `id=%0431a9ab3004b4b9` part the same as `pkcs11-tool`. If you want to use the numeric id, you must prefix every hexadecimal byte with a percent sign like this: `id=%04%31%a9%ab%30%04%b4%b9`.

</details>

## Get your public key
If you have the URI of the public key, you can just extract and store it into PEM like this:
```sh
openssl pkey -in <YOUR_PUBKEY_URI> -pubin -pubout -out pubkey.pem
```

## Create a signature
If you have the URI of the private key, you can sign a file like this:
```sh
openssl pkeyutl -sign -inkey <YOUR_PRIVKEY_URI> -in msg -rawin -out msg.sig
```

## Verify a signature
Gg18 creates ECDSA signatures, so you can use any tool to verify them. Using OpenSSL for example:
```sh
openssl pkeyutl -verify -in msg -rawin -sigfile msg.sig -inkey pubkey.pem -pubin
```
