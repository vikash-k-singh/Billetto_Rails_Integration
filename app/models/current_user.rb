class CurrentUser
  attr_reader :id

  def initialize(id:)
    @id = id.to_s
  end
end
