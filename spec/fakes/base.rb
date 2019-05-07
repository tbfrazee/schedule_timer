class FakeBase

  def initialize(id = 1)
    @id = id
    @log = []
  end

  def self.all
    [self.new]
  end

  def id
    @id
  end

  def [](attr)
    send(attr)
  end

  def log
    puts "LOG: #{@log}"
    @log
  end

end
