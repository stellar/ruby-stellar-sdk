require "simplecov"
require "pry-byebug"

require "rspec/its"

require_relative "../lib/stellar-sdk"

require_relative "support/vcr"

CONFIG = {
  source_address: "GCIDYJRG5HV4WEESRA4LEKIMXLCU46XIKXGZK4PWX5K23PJIATMWR3UE",
  source_seed: "SALQBNNRCXWD32E4QKIXKXCMXCPJKWUP34EAK53SP6PNGAUVWSAM5IUQ",
  channel_address: "GBLVRKRL4NCY6MBDPRYMH4CQZMYME2CJGCVAD5YSRPDUS74AREQE7QOK",
  channel_seed: "SAOS5HRNKGRGFVQQPEZOJN33MHUGHMS6GR3LB7GWFJFKSVSWIFYMQYFM"
}

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
