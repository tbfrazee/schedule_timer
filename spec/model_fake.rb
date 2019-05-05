class ModelFake

  def on_start
    puts "Start"
  end

  def on_end
    puts "End"
  end

  def on_interval
    puts "Interval"
  end

  def on_interrupt
    puts "Interrupt"
  end

  def self.all
    [ModelFake.new]
  end

  def id
    1
  end

  def [](attr)
    send(attr)
  end

end
