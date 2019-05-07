require 'fakes/base'

class Counter < FakeBase

  def on_start
    @count = 1
  end

  def on_end
    @count += 1
  end

  def on_interval
    @count += 1
  end

  def on_interrupt
    @count += 1
  end

  def interval
    1
  end

  def get_count
    @count
  end

end
