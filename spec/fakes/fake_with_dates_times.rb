require 'date'

class FakeWithDatesTimes < Counter

  def initialize(id = 1)
    super(id)
    @start_time = Time.now + 5
    @end_time = Time.now + 15
    @start_date = Date.today
    @end_date = Date.today
  end

  def start_time
    @start_time
  end

  def end_time
    @end_time
  end

  def start_date
    @start_date
  end

  def end_date
    @end_date
  end

end
