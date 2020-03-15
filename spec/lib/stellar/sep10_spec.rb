require "spec_helper"

describe Stellar::SEP10 do

  subject(:sep10) { Stellar::SEP10 }

  let(:server) { Stellar::KeyPair.random }
  let(:user) { Stellar::KeyPair.random }
  let(:anchor) { "SDF" }
  let(:timeout) { 600 }
  let(:envelope) { Stellar::TransactionEnvelope.from_xdr(subject, "base64") }
  let(:transaction) { envelope.tx }  

  subject do
    sep10.build_challenge_tx(server: server, client: user, anchor_name: anchor, timeout: timeout) 
  end
  
  describe "#build_challenge_tx" do      
    it "generates a valid SEP10 challenge" do
      expect(transaction.seq_num).to eql(0)
      expect(transaction.operations.size).to eql(1);
      expect(transaction.source_account).to eql(server.public_key);

      time_bounds = transaction.time_bounds
      expect(time_bounds.max_time - time_bounds.min_time).to eql(600)
      operation = transaction.operations.first

      expect(operation.body.arm).to eql(:manage_data_op)
      expect(operation.body.value.data_name).to eql("SDF auth")
      expect(operation.source_account).to eql(user.public_key)
      data_value = operation.body.value.data_value
      expect(data_value.bytes.size).to eql(64)
      expect(data_value.unpack("m")[0].size).to eql(48)
    end

    describe "defaults" do
      subject do
        sep10.build_challenge_tx(server: server, client: user, anchor_name: anchor) 
      end
      
      it "has a default timeout of 300 seconds (5 minutes)" do
        time_bounds = transaction.time_bounds
        expect(time_bounds.max_time - time_bounds.min_time).to eql(300)
      end
    end
  end

  describe "#read_challenge_tx" do
    subject do
      challenge = super()
      envelope = Stellar::TransactionEnvelope.from_xdr(challenge, 'base64')
      envelope.tx.to_envelope(server, user).to_xdr(:base64)
    end
    
    it "returns the envelope and client public key if the transaction is valid" do
      expect(sep10.read_challenge_tx(challenge: subject, server: server)).to eql([envelope, user.address])
    end

    it "throws an error if transaction sequence number is different to zero"  do
      envelope.tx.seq_num = 1

      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)
      }.to raise_error(Stellar::InvalidSep10ChallengeError, /The transaction sequence number should be zero/)
    end      

    it "throws an error if transaction source account is different to server account id"  do
      expect {
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: Stellar::KeyPair.random)
      }.to raise_error(Stellar::InvalidSep10ChallengeError, /The transaction source account is not equal to the server's account/)
    end

    it "throws an error if transaction doestn't contain any operation" do
      envelope.tx.operations = []

      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)
      }.to raise_error(Stellar::InvalidSep10ChallengeError, /The transaction should contain only one operation/)
      end

    it "throws an error if operation does not contain the source account" do
      op = envelope.tx.operations[0]
      op.source_account = nil

      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)
      }.to raise_error(Stellar::InvalidSep10ChallengeError, /The transaction's operation should contain a source account/)
      end
      
    it "throws an error if operation is not manage data"  do
      envelope.tx.operations = [ 
        Stellar::Operation.payment(
          destination: Stellar::KeyPair.random, 
          amount: [:native, 20],
          source_account: Stellar::KeyPair.random
        )
      ]

      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)
      }.to raise_error(Stellar::InvalidSep10ChallengeError, /The transaction's operation should be manageData/)
      end

    it "throws an error if operation value is not a 64 bytes base64 string" do
      transaction.operations[0].body.value.data_value = SecureRandom.random_bytes(64)
      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)          
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction's operation value should be a 64 bytes base64 random string/
      )
    end

    it "throws an error if transaction is not signed by the server" do
      envelope.signatures = envelope.signatures.slice(1, 2)
      
      expect { 
        sep10.read_challenge_tx(challenge: envelope.to_xdr(:base64), server: server)          
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction is not signed by the server/
      )
    end


    it "throws an error if transaction does not contain valid timeBounds" do
      envelope.tx.time_bounds = nil
      challenge = envelope.tx.to_envelope(server, user).to_xdr(:base64)

      expect { 
        sep10.read_challenge_tx(challenge: challenge, server: server)          
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction has expired/
      )

      envelope.tx.time_bounds = Stellar::TimeBounds.new(min_time: 0, max_time: 5)
      challenge = envelope.tx.to_envelope(server, user).to_xdr(:base64)

      expect { 
        sep10.read_challenge_tx(challenge: challenge, server: server)          
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction has expired/
      )

      now = Time.now.to_i
      envelope.tx.time_bounds = Stellar::TimeBounds.new(
        min_time: now + 100, 
        max_time: now + 500
      )
      challenge = envelope.tx.to_envelope(server, user).to_xdr(:base64)

      expect { 
        sep10.read_challenge_tx(challenge: challenge, server: server)          
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction has expired/
      )
    end
  end

  describe "#verify_challenge_transaction_threshold" do
    it "verifies proper challenge and threshold" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      transaction = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      transaction.signatures += [
        client_kp_a, client_kp_b, client_kp_c
      ].map { |kp| transaction.tx.sign_decorated(kp) }
      challenge_tx = transaction.to_xdr(:base64)

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
      ]

      signers_found = sep10.verify_challenge_transaction_threshold(
        challenge_transaction: challenge_tx,
        server: server_kp,
        threshold: 7,
        signers: signers,
      )
      expect(signers_found).to eql(signers)
    end

    it "raises error when signers don't meet threshold" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      transaction = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      transaction.signatures.push(transaction.tx.sign_decorated(client_kp_a))
      challenge_tx = transaction.to_xdr(:base64)

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
      ]

      expect {
        sep10.verify_challenge_transaction_threshold(
          challenge_transaction: challenge_tx,
          server: server_kp,
          threshold: 7,
          signers: signers,
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        "signers with weight %d do not meet threshold %d." % [1, 7]
      )
    end
  end

  describe "#verify_challenge_transaction" do
    it "verifies proper challenge transaction" do
      server_kp = Stellar::KeyPair.random
      client_kp = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      envelope.signatures.push(envelope.tx.sign_decorated(client_kp))
      challenge_tx = envelope.to_xdr(:base64)

      sep10.verify_challenge_transaction(
        challenge_transaction: challenge_tx, 
        server: server_kp
      )
    end

    it "raises not signed by client" do
      server_kp = Stellar::KeyPair.random
      client_kp = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      expect {
        sep10.verify_challenge_transaction(
          challenge_transaction: challenge, 
          server: server_kp
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        "Transaction not signed by client: %s" % [client_kp.address]
      )
    end
  end

  describe "#verify_challenge_transaction_signers" do
    it "returns expected signatures" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      challenge_envelope.signatures += [
        client_kp_a, client_kp_b, client_kp_c
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 255),
      ]
      signers_found = sep10.verify_challenge_transaction_signers(
        challenge: challenge_envelope.to_xdr(:base64), 
        server: server_kp, 
        signers: signers
      )
      expect(signers_found).to eql([
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
      ])
    end

    it "raises no signature error" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      challenge_envelope.signatures += [
        client_kp_a, client_kp_b, client_kp_c
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 1),
      ]

      expect {
        sep10.verify_challenge_transaction_signers(
          challenge: challenge_envelope.to_xdr(:base64), 
          server: server_kp, 
          signers: []
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /No signers provided./
      )
    end

    it "raises transaction not signed by server" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      challenge_envelope.signatures = [client_kp_a, client_kp_b, client_kp_c].map { 
        |kp| challenge_envelope.tx.sign_decorated(kp) 
      }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4),
      ]

      expect {
        sep10.verify_challenge_transaction_signers(
          challenge: challenge_envelope.to_xdr(:base64), 
          server: server_kp, 
          signers: signers
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /The transaction is not signed by the server/
      )
    end

    it "raises no client signers found" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      challenge_envelope.signatures += [
        client_kp_a, client_kp_b, client_kp_c
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      # Different signers than those on the transaction envelope
      signers = [
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 1),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 1),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 1),
      ]

      expect {
        sep10.verify_challenge_transaction_signers(
          challenge: challenge_envelope.to_xdr(:base64), 
          server: server_kp, 
          signers: signers
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /Transaction not signed by any client signer./
      )
    end

    it "raises unrecognized signatures" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout,
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")
      # Add random signature
      challenge_envelope.signatures += [
        client_kp_a, client_kp_b, client_kp_c, Stellar::KeyPair.random
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 4)
      ]

      expect {
        sep10.verify_challenge_transaction_signers(
          challenge: challenge_envelope.to_xdr(:base64), 
          server: server_kp, 
          signers: signers
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /Transaction has unrecognized signatures./
      )
    end
  end

  describe "#verify_transaction_signatures" do
    it "returns expected signatures" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      client_kp_b = Stellar::KeyPair.random
      client_kp_c = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")

      challenge_envelope.signatures += [
        client_kp_a, client_kp_b, client_kp_c
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 3),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 4),
      ]
      signers_found = sep10.verify_transaction_signatures(
        transaction_envelope: challenge_envelope, signers: signers
      )
      expect(signers_found).to eql([
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_b.address, 2),
        Stellar::AccountSigner.new(client_kp_c.address, 3),
      ])
    end

    it "raises no signature error" do
      server_kp = Stellar::KeyPair.random
      client_kp = Stellar::KeyPair.random
      value = SecureRandom.base64(48)
            
      tx = Stellar::Transaction.manage_data({
        account: server_kp,
        sequence:  0,
        name: "SDF auth", 
        value: value,
        source_account: client_kp
      })

      now = Time.now.to_i
      tx.time_bounds = Stellar::TimeBounds.new(
        min_time: now, 
        max_time: now + timeout
      )

      signers = [Stellar::AccountSigner.new(client_kp.address)]
      expect{
        sep10.verify_transaction_signatures(
          transaction_envelope: tx.to_envelope(), signers: signers
        )
      }.to raise_error(
        Stellar::InvalidSep10ChallengeError,
        /Transaction has no signatures./
      )
    end

    it "removes duplicate signers" do
      server_kp = Stellar::KeyPair.random
      client_kp_a = Stellar::KeyPair.random
      timeout = 600
      anchor_name = "SDF"

      challenge = sep10.build_challenge_tx(
        server: server_kp,
        client: client_kp_a,
        anchor_name: anchor_name,
        timeout: timeout
      )

      challenge_envelope = Stellar::TransactionEnvelope.from_xdr(challenge, "base64")

      # Sign the transaction with the same keypair twice
      challenge_envelope.signatures += [
        client_kp_a, client_kp_a
      ].map { |kp| challenge_envelope.tx.sign_decorated(kp) }

      signers = [
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(client_kp_a.address, 1),
        Stellar::AccountSigner.new(Stellar::KeyPair.random.address, 4),
      ]
      signers_found = sep10.verify_transaction_signatures(
        transaction_envelope: challenge_envelope, signers: signers
      )
      expect(signers_found).to eql([
        Stellar::AccountSigner.new(client_kp_a.address, 1)
      ])
    end
  end

  describe "#verify_tx_signed_by" do
    let(:keypair) { Stellar::KeyPair.random }
    let(:envelope) do
      Stellar::Transaction.bump_sequence(account: keypair, bump_to: 1000, sequence: 0).to_envelope(keypair)
    end
    
    it "returns true if transaction envelope is signed by keypair" do
      result = sep10.verify_tx_signed_by(transaction_envelope: envelope, keypair: keypair)
      expect(result).to eql(true)
    end
    
    it "returns false if transaction envelope is not signed by keypair" do
      result = sep10.verify_tx_signed_by(
        transaction_envelope: envelope, 
        keypair: Stellar::KeyPair.random
      )
      expect(result).to eql(false)
    end
  end
end