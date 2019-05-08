class Sleeper < Counter

  def on_start
    super
    sleep(9)
  end

end
