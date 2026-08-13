module ObjectRepository
  @registry = {}

  def self.register(model_class)
    prefix = model_class.name.demodulize.underscore
    @registry[prefix] = model_class
  end

  def self.find(tid)
    prefix = tid.to_s.split("_").first
    model_class = @registry[prefix]
    raise "Unknown type prefix '#{prefix}' for tid '#{tid}'" unless model_class

    model_class.find_by!(tid: tid)
  end
end
