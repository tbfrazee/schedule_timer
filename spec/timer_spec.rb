require 'spec_helper'
require 'model_fake'
describe ScheduleTimer::Timer do
  context "When loading timer" do

    it "should raise ArgumentError" do
      expect {ScheduleTimer::Timer.new(ModelFake, {:tick_interval => nil})}.to raise_error(ArgumentError)
    end

    it "should start" do
      timer = ScheduleTimer::Timer.new(ModelFake)
      expect(timer.start).to be true
    end

    it "should start and then stop" do
      timer = ScheduleTimer::Timer.new(ModelFake)
      timer.start
      expect(timer.stop).to be true
    end

    it "should start and then interrupt" do
      timer = ScheduleTimer::Timer.new(ModelFake)
      timer.start
      expect(timer.interrupt).to be true
    end

  end
end
