module Stellar
  class HorizonError < StandardError
    attr_reader :original_response, :extras

    def self.make(original_response)
      klass = class_for(original_response["title"])
      klass.new(original_response)
    end

    # Uses specialized class if it is defined
    def self.class_for(title)
      const_get title.delete(" ").to_sym
    rescue NameError
      self
    end

    def initialize(original_response)
      message = make_message(
        detail: original_response["detail"],
        title: original_response["title"]
      )

      # Superclass StandardError has different argument signature
      super(message)

      @original_response = original_response
      @extras = original_response["extras"]
    end

    private

    def make_message(detail:, title:)
      # Include title only on generic class
      # Condition passes only for child classes
      if self.class != HorizonError
        title = nil
      end

      [title, detail].compact.join(": ")
    end

    class TransactionFailed < self
      def make_message(detail:)
        detail.sub!(
          "The `extras.result_codes` field on this response contains further details.",
          "extras.result_codes contained: `#{hash.dig("extras", "result_codes")}`"
        )
      end
    end

    class TransactionMalformed < self; end
  end
end
