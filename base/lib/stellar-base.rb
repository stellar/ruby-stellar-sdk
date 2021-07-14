require "xdr"
require "rbnacl"
require "digest/sha2"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/kernel/reporting"
require "active_support/core_ext/module/attribute_accessors_per_thread"
require "active_support/core_ext/module/delegation"
require "active_support/deprecation"

require_relative "stellar/ext/xdr"

# See ../generated for code-gen'ed files
silence_warnings do
  require "stellar-base-generated"
end
Stellar.load_all!

require_relative "stellar/version"

Stellar::ONE = 1_0000000
Stellar::Deprecation = ActiveSupport::Deprecation.new("next release", "stellar-base")

# extensions onto the generated files must be loaded manually, below

require_relative "./stellar/account"
require_relative "./stellar/account_flags"
require_relative "./stellar/asset"
require_relative "./stellar/claim_predicate"
require_relative "./stellar/key_pair"
require_relative "./stellar/ledger_key"
require_relative "./stellar/networks"
require_relative "./stellar/operation"
require_relative "./stellar/path_payment_strict_receive_result"
require_relative "./stellar/price"
require_relative "./stellar/signer_key"
require_relative "./stellar/thresholds"
require_relative "./stellar/trust_line_flags"

require_relative "./stellar/concerns/transaction"
require_relative "./stellar/fee_bump_transaction"
require_relative "./stellar/transaction"
require_relative "./stellar/transaction_builder"
require_relative "./stellar/transaction_envelope"
require_relative "./stellar/transaction_v0"

require_relative "./stellar/util/strkey"
require_relative "./stellar/convert"

require_relative "./stellar/dsl"

require_relative "./stellar/compat"
