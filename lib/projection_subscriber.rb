class ProjectionSubscriber
  def initialize(handler_class)
    @handler_class = handler_class
  end

  def call(fact)
    @handler_class.new.call(fact)
  end
end
