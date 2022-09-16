import { Button, Divider, Input } from "antd";
import React, { useState } from "react";

import { Address, Events } from "../components";

export default function ExampleUI({
  contractState,
  consent,
  partner1,
  partner2,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  price,
  tx,
  readContracts,
  writeContracts,
}) {
  const [message, setMessage] = useState("Cheers! 🥂");

  const isPartner = address === partner1 || address === partner2;
  const witnessReady = contractState && (contractState === 1 || contractState === 2);

  return (
    <div>
      {/*
        ⚙️ Here is an example UI that displays and sets the purpose in your smart contract:
      */}
      <div style={{ border: "1px solid #cccccc", padding: 16, width: 400, margin: "auto", marginTop: 64 }}>
        <h2>Tronix Constitution:</h2>
        <h4>Partners: </h4>
        <Address
          address={partner1} /* this will show as austingriffith.eth */
          ensProvider={mainnetProvider}
          fontSize={16}
        />
        <br />
        <Address
          address={partner2} /* this will show as austingriffith.eth */
          ensProvider={mainnetProvider}
          fontSize={16}
        />
        <Divider />
        <div style={{ margin: 8 }}>
          {isPartner ? (
            <Button
              style={{ marginTop: 8 }}
              disabled={contractState !== 0 || consent}
              onClick={async () => {
                /* look how you call setPurpose on your contract: */
                /* notice how you pass a call back for tx updates too */
                const result = tx(writeContracts.SmartKetubah.recordConsent(), update => {
                  console.log("📡 Transaction Update:", update);
                  if (update && (update.status === "confirmed" || update.status === 1)) {
                    console.log(" 🍾 Transaction " + update.hash + " finished!");
                    console.log(
                      " ⛽️ " +
                        update.gasUsed +
                        "/" +
                        (update.gasLimit || update.gas) +
                        " @ " +
                        parseFloat(update.gasPrice) / 1000000000 +
                        " gwei",
                    );
                  }
                });
                console.log("awaiting metamask/web3 confirm result...", result);
                console.log(await result);
              }}
            >
              Consent
            </Button>
          ) : (
            <div>
              <Input
                onChange={e => {
                  setMessage(e.target.value);
                }}
                defaultValue={"Cheers! 🥂"}
              />
              <Button
                style={{ marginTop: 8 }}
                disabled={!witnessReady}
                onClick={async () => {
                  /* look how you call setPurpose on your contract: */
                  /* notice how you pass a call back for tx updates too */
                  const result = tx(writeContracts.SmartKetubah.witness(message), update => {
                    console.log("📡 Transaction Update:", update);
                    if (update && (update.status === "confirmed" || update.status === 1)) {
                      console.log(" 🍾 Transaction " + update.hash + " finished!");
                      console.log(
                        " ⛽️ " +
                          update.gasUsed +
                          "/" +
                          (update.gasLimit || update.gas) +
                          " @ " +
                          parseFloat(update.gasPrice) / 1000000000 +
                          " gwei",
                      );
                    }
                  });
                  console.log("awaiting metamask/web3 confirm result...", result);
                  console.log(await result);
                }}
              >
                Witness!
              </Button>
            </div>
          )}
        </div>
      </div>
      {/*
        📑 Maybe display a list of events?
          (uncomment the event and emit line in YourContract.sol! )
      */}
      <Events
        contracts={readContracts}
        contractName="SmartKetubah"
        eventName="Witnessed"
        localProvider={localProvider}
        mainnetProvider={mainnetProvider}
        startBlock={1}
      />
    </div>
  );
}
