require "stellar-base"

module Stellar
  module SDK
    VERSION = ::Stellar::VERSION
  end

  autoload :Account
  autoload :Amount
  autoload :Client
  autoload :SEP10
  autoload :HorizonError

  module Horizon
    extend ActiveSupport::Autoload

    autoload :Problem
    autoload :Result
  end

  autoload :TransactionPage
end
