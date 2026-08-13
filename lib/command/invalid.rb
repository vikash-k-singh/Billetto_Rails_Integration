module Command
  class Invalid < StandardError
    attr_reader :command

    def initialize(command)
      @command = command
      super(error_message(command))
    end

    private

    def error_message(command)
      return "Invalid command" unless command.respond_to?(:errors)

      messages = Array(command.errors[:base]) +
                 command.errors.attribute_names.flat_map { |attr| command.errors[attr] }
      messages.map(&:to_s).reject(&:blank?).to_sentence.presence || "Invalid command"
    rescue ArgumentError
      "Invalid command"
    end
  end
end
