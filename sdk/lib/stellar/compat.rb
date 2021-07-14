class << Stellar::Account
  delegate :lookup, to: Stellar::Federation
  deprecate deprecator: Stellar::Deprecation, lookup: "Use `Stellar::Federation.lookup` method"
end
