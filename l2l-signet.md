Instructions on setting up the signet. This is using Fish shell, but should be
easy enough to get the gist if using an inferior shell like Bash or Zsh.

1.  Create the appropriate configuration file for our network:

    ```conf
    signet=1

     # 1 minute block times. Note that /everyone/ who connects to this signet
     # must have this exact configuration value.
    signetblocktime=60

    ```

1.  Generate the private key used to sign blocks + corresponding
    `signetchallenge` value.

    ```fish
    $ mkdir l2l-signet
    $ ./build/src/bitcoind -daemon -regtest -datadir=$PWD/l2l-signet

    $ ./build/src/bitcoin-cli -regtest -datadir=$PWD/l2l-signet \
         createwallet l2l-signet

    $ set address (./build/src/bitcoin-cli -regtest -datadir=$PWD/l2l-signet getnewaddress)

    $ set signet_challenge (./build/src/bitcoin-cli -regtest -datadir=$PWD/l2l-signet \
                         getaddressinfo $address | jq -r .scriptPubKey)

    $ echo signetchallenge=$signet_challenge >> l2l-signet/bitcoin.conf

    # Need the wallet descriptors to be able to import the wallet into
    $ set descriptors (./build/src/bitcoin-cli -regtest -datadir=$PWD/l2l-signet \
                         listdescriptors true | jq -r .descriptors)

    # We're finished with the regtest wallet!
    $ ./build/src/bitcoin-cli -regtest -datadir=$PWD/l2l-signet stop
    ```

1.  Create the signet wallet

    ```fish
    $ ./build/src/bitcoind -daemon -signet -datadir=$PWD/l2l-signet

    $ ./build/src/bitcoin-cli -signet -datadir=$PWD/l2l-signet \
         createwallet l2l-signet

    $ ./build/src/bitcoin-cli -signet -datadir=$PWD/l2l-signet \
        importdescriptors "$descriptors"

    ```

1.  Start mining on our network:

    ```fish
    $ set address (./build/src/bitcoin-cli -signet -datadir=$PWD/l2l-signet getnewaddress)

    $ ./contrib/signet/miner \
        --cli "bitcoin-cli -signet -datadir=$PWD/l2l-signet" \
        generate --address $address \
        --grind-cmd "$PWD/build/src/bitcoin-util grind" \
        --min-nbits --ongoing --block-interval 60
    ```

```

```

```

```
