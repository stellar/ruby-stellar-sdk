require "simplecov"
require "pry-byebug"

require "rspec/its"

require_relative "../lib/stellar-base"

require_relative "support/matchers/be_strkey"
require_relative "support/matchers/eq_bytes"
require_relative "support/matchers/have_length"

RSpec.configure do |config|
  config.include Stellar::DSL

  config.filter_run_when_matching focus: true
  config.run_all_when_everything_filtered = true

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
