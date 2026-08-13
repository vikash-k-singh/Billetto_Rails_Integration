class Fact < RailsEventStore::Event
  def self.strict(data:)
    normalized = data.transform_keys(&:to_sym)
    validate_schema!(normalized)
    new(data: normalized)
  end

  def stream_names
    raise NotImplementedError, "#{self.class} must implement #stream_names"
  end

  private_class_method def self.validate_schema!(data)
    return unless const_defined?(:SCHEMA, false)

    schema_keys = self::SCHEMA.keys.map(&:to_sym).to_set
    data_keys   = data.keys.map(&:to_sym).to_set

    missing = schema_keys - data_keys
    extra   = data_keys - schema_keys

    raise ArgumentError, "#{name}: missing keys #{missing.to_a}"   if missing.any?
    raise ArgumentError, "#{name}: unknown keys #{extra.to_a}"     if extra.any?

    self::SCHEMA.each do |key, type|
      value = data[key.to_sym]
      unless value.is_a?(type)
        raise ArgumentError, "#{name}: #{key} must be #{type}, got #{value.class}"
      end
    end
  end
end