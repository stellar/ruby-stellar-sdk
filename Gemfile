source "https://rubygems.org"

gem "stellar-base", path: "./base"
gem "stellar-sdk", path: "./sdk"
# gem "xdr", github: "astroband/ruby-xdr"

group :test do
  gem "rake"
  gem "rspec"
  gem "rspec-its"
  gem "vcr"
  gem "yard"
  gem "webmock"

  gem "codecov", require: false
  gem "simplecov", "~> 0.21.2", require: false
  gem "simplecov_json_formatter"
end

group :lint do
  gem "bundler-audit"
  gem "standard", "1.0.5", require: false
  gem "yard-junk", require: false
end

group :development do
  gem "amazing_print"
  gem "break"
  gem "faraday"
  gem "faraday_middleware"
  gem "gem-release", require: false
  gem "octokit"
  gem "byebug", platform: %i[mri truffleruby]
  gem "pry-byebug", require: false
  gem "pry-doc"
  gem "netrc"
  gem "xdrgen"
end

group :guard, optional: true do
  gem "guard-rspec"
end
