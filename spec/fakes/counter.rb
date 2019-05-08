require 'fakes/base'

class Counter < FakeBase

  def initialize(id = 1)
    super(id)
    @count = 0
  end

  def on_start
    @count += 1
    puts "Counter Start"
  end

  def on_end
    @count += 1
    puts "Counter end"
  end

  def on_interval
    @count += 1
    puts "Counter interval"
  end

  def on_interrupt
    @count += 1
    puts "Counter interrupt"
  end

  def interval
    1
  end

  def get_count
    @count
  end

end
