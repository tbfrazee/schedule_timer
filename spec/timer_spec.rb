require 'spec_helper'
require 'fakes/fake_model'
require 'fakes/fake_model_no_methods'
require 'fakes/counter'
require 'fakes/fake_with_dates_times'

require 'byebug'
require 'logger'

describe ScheduleTimer::Timer do
  context "When loading timer" do

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    opts = {
      :logger => logger
    }

    it "should raise ArgumentError" do
      expect {ScheduleTimer::Timer.new(FakeModel, opts.merge({:tick_interval => nil}))}.to raise_error(ArgumentError)
    end

    it "should start" do
      timer = ScheduleTimer::Timer.new(FakeModel, opts)
      expect(timer.start).to be true
    end

    it "should start and then stop" do
      timer = ScheduleTimer::Timer.new(FakeModel, opts)
      timer.start
      sleep(1)
      timer.stop
      model = timer.get_loaded_models[1]
      expect(model.log).to match_array(["Start"])
    end

    it "should start and then interrupt" do
      timer = ScheduleTimer::Timer.new(FakeModelNoMethods, opts)
      timer.start
      expect(timer.interrupt).to be true
    end

    it "should start and then interrupt with logging" do
      timer = ScheduleTimer::Timer.new(FakeModel, opts)
      timer.start
      sleep(1)
      timer.interrupt
      sleep(1)
      model = (timer.get_loaded_models)[1]
      expect(model.log).to match_array(["Start", "Interrupt"])
    end

    it "should count 2 (start, interval) in 2 ticks" do
      timer = ScheduleTimer::Timer.new(Counter, opts.merge({
        :tick_interval => 2
      }))
      timer.start
      sleep(3)
      timer.stop
      model = timer.get_loaded_models[1]
      expect(model.get_count).to eq 2
    end

    it "should count 3 (start, interval, end)" do
      timer = ScheduleTimer::Timer.new(FakeWithDatesTimes, opts.merge({
        :tick_interval => 5
      }))
      timer.start
      sleep(20)
      timer.stop
      model = timer.get_loaded_models[1]
      expect(model.get_count).to eq 3
    end


  end
end
