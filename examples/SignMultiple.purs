-- | This module balances and signs two transactions at once and demonstrates
-- | the `withBalancedandSignedTxs` bracket. The point is that two different
-- | Utxos will be used for these transactions.
module Examples.SignMultiple (main) where

import Contract.Prelude

import Contract.Address (ownPaymentPubKeyHash, ownStakePubKeyHash)
import Contract.Config (testnetNamiConfig)
import Contract.Log (logInfo')
import Contract.Monad (Contract, launchAff_, liftedE, liftedM, runContract)
import Contract.ScriptLookups as Lookups
import Contract.Transaction
  ( BalancedSignedTransaction
  , submit
  , withBalancedAndSignedTxs
  )
import Contract.TxConstraints as Constraints
import Contract.Value as Value
import Control.Monad.Reader (asks)
import Data.BigInt as BigInt
import Effect.Ref as Ref
import Types.UsedTxOuts (TxOutRefCache)

getLockedInputs :: forall (r :: Row Type). Contract r TxOutRefCache
getLockedInputs = do
  cache <- asks (_.usedTxOuts <<< _.runtime <<< unwrap)
  liftEffect $ Ref.read $ unwrap cache

main :: Effect Unit
main = launchAff_ do
  runContract testnetNamiConfig do
    logInfo' "Running Examples.Pkh2Pkh"
    pkh <- liftedM "Failed to get own PKH" ownPaymentPubKeyHash
    skh <- liftedM "Failed to get own SKH" ownStakePubKeyHash

    let
      constraints :: Constraints.TxConstraints Void Void
      constraints = Constraints.mustPayToPubKeyAddress pkh skh
        $ Value.lovelaceValueOf
        $ BigInt.fromInt 2_000_000

      lookups :: Lookups.ScriptLookups Void
      lookups = mempty

    ubTx1 <- liftedE $ Lookups.mkUnbalancedTx lookups constraints
    ubTx2 <- liftedE $ Lookups.mkUnbalancedTx lookups constraints

    withBalancedAndSignedTxs [ ubTx1, ubTx2 ] $ \txs -> do
      locked <- getLockedInputs
      logInfo' $ "Locked inputs inside bracket (should be nonempty): " <> show
        locked
      traverse_ submitAndLog txs

    locked <- getLockedInputs
    logInfo' $ "Locked inputs after bracket (should be empty): " <> show locked

  where
  submitAndLog
    :: forall (r :: Row Type). BalancedSignedTransaction -> Contract r Unit
  submitAndLog bsTx = do
    txId <- submit bsTx
    logInfo' $ "Tx ID: " <> show txId
