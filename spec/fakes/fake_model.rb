require 'fakes/base'

class FakeModel < FakeBase

  def on_start
    @log.push "Start"
  end

  def on_end
    @log.push "End"
  end

  def on_interval
    @log.push "Interval"
  end

  def on_interrupt
    @log.push "Interrupt"
  end

end
