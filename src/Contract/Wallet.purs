-- | A module with Wallet-related functionality.
module Contract.Wallet
  ( mkNamiWallet
  , mkGeroWallet
  , module ContractAddress
  , module Wallet
  ) where

import Contract.Monad (Contract)
import Effect.Aff.Class (liftAff)
import Wallet
  ( Cip30Connection
  , Cip30Wallet
  , Wallet(..)
  , mkNamiWalletAff
  , mkGeroWalletAff
  ) as Wallet
import Contract.Address
  ( getWalletAddress
  , getWalletCollateral
  ) as ContractAddress

-- | Make a wallet lifted into `Contract` from `Aff`.
mkNamiWallet :: forall (r :: Row Type). Contract r Wallet.Wallet
mkNamiWallet = liftAff Wallet.mkNamiWalletAff

mkGeroWallet :: forall (r :: Row Type). Contract r Wallet.Wallet
mkGeroWallet = liftAff Wallet.mkGeroWalletAff
