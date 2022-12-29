import * as aptos from "aptos";
import { EntryFunctionPayload } from "aptos/src/generated";

const CONTRACT_ADDRESS =
  "0x4c36d0311d6cf500b35d1dfa5f9a7e83d3dfeed7f9b8404876e16a4378a73620";
const CLIENT = new aptos.AptosClient(
  "https://fullnode.testnet.aptoslabs.com/v1/"
);
const USER = new aptos.AptosAccount(
  new aptos.HexString(
    "key"
  ).toUint8Array()
);
const DEFAULT_TXN_CONFIG = {
  maxGasAmount: 10000n,
  gasUnitPrice: 100n,
  txnExpirationOffset: 10n,
};

async function main() {
  let payload: EntryFunctionPayload = {
    function: `${CONTRACT_ADDRESS}::kana_staking::invoke_ditto_stake_aptos`,
    arguments: [100000000],
    type_arguments: [],
  };

  let address = USER.address();
  console.log("address",address);
  let txn = await CLIENT.generateTransaction(address, payload, {
    max_gas_amount: DEFAULT_TXN_CONFIG.maxGasAmount.toString(),
    gas_unit_price: DEFAULT_TXN_CONFIG.gasUnitPrice.toString(),
    expiration_timestamp_secs: (
      BigInt(Math.floor(Date.now() / 1000)) +
      DEFAULT_TXN_CONFIG.txnExpirationOffset
    ).toString(),
  });
  let signedTx = await CLIENT.signTransaction(USER, txn);
  let response = await CLIENT.submitTransaction(signedTx);
  await CLIENT.waitForTransaction(response.hash);
  let txnInfo: aptos.Types.Transaction;
  try {
    txnInfo = await CLIENT.getTransactionByHash(response.hash);
  } catch (e) {
    throw Error("Transaction hash can't be found.");
  }
  console.log(txnInfo.hash, (txnInfo as any).vm_status);
}

main();