# Automatically generated on 2015-05-13T15:00:04-07:00
# DO NOT EDIT or your changes may be overwritten
        
require 'xdr'

# === xdr source ============================================================
#
#   struct
#       {
#           AccountID accountID;
#           uint64 offerID;
#       }
#
# ===========================================================================
module Stellar
  class LedgerKey
    class Offer < XDR::Struct
      attribute :account_id, AccountID
      attribute :offer_id,   Uint64
    end
  end
end