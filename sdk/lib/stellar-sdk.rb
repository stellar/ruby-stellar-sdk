require "stellar-base"

module Stellar
  module SDK
    VERSION = ::Stellar::VERSION
  end

  autoload :Amount
  autoload :Client
  autoload :Federation
  autoload :SEP10

  module Horizon
    extend ActiveSupport::Autoload

    autoload :Problem
    autoload :Result
  end

  autoload :TransactionPage
end

require_relative "stellar/compat"
