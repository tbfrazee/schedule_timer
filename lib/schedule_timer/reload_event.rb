class ScheduleTimer::ReloadEvent

	def initialize(timer, reload_at)
		@timer = timer
		@start_time = reload_at
	end

	def start_time
		@start_time
	end

	def on_start
		@timer.schedule_reload
	end

end
