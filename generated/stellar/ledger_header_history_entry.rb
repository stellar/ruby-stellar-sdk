# Automatically generated on 2015-04-07T10:52:07-07:00
# DO NOT EDIT or your changes may be overwritten
        
require 'xdr'

# === xdr source ============================================================
#
#   struct LedgerHeaderHistoryEntry
#   {
#       Hash hash;
#       LedgerHeader header;
#   };
#
# ===========================================================================
module Stellar
  class LedgerHeaderHistoryEntry < XDR::Struct
    attribute :hash,   Hash
    attribute :header, LedgerHeader
  end
end