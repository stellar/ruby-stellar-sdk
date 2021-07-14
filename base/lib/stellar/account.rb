module Stellar
  class Account
    delegate :address, to: :keypair

    def self.random
      keypair = Stellar::KeyPair.random
      new(keypair)
    end

    def self.from_seed(seed)
      keypair = Stellar::KeyPair.from_seed(seed)
      new(keypair)
    end

    def self.from_address(address)
      case address[0]
      when "G"
        keypair = Stellar::KeyPair.from_address(address)
        new(keypair)
      when "M"
        payload = Util::StrKey.check_decode(:muxed, address)
        # for muxed accounts first 32 bytes of payload are raw public key
        keypair = KeyPair.from_public_key(payload[0..31])
        id = Uint64.from_xdr(payload[32..-1])

        new(keypair, id)
      else
        raise ArgumentError, "Unknown type of address: `#{address}`"
      end
    end

    def self.master
      keypair = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
      new(keypair)
    end

    attr_reader :keypair, :id

    # @param [Stellar::KeyPair] keypair
    # @param [Integer] id
    def initialize(keypair, id = nil)
      @keypair = keypair
      @id = id
    end

    def to_muxed
      med25519 = Stellar::MuxedAccount::Med25519.new(id: id, ed25519: keypair.raw_public_key)
      Stellar::MuxedAccount.new(:key_type_muxed_ed25519, med25519)
    end

    def to_ed25519
      Stellar::MuxedAccount.new(:key_type_ed25519, keypair.raw_public_key)
    end

    def address(force_account_id: true)
      return keypair.address if force_account_id

      Util::StrKey.check_encode(:muxed, keypair.raw_public_key + [id].pack("Q>"))
    end

    def to_keypair
      keypair
    end
  end
end
