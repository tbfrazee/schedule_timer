##
# The Timer part of ScheduleTimer
# Each Timer object, when started via the Timer::start method,
# instantiates a new Thread to keep track of time without blocking the main thread.
# The Timer wakes up each tick interval and checks to see if any start, end, or interval times
# have passed, and calls the associated methods on model_class as appropriate.
#
# Timer has a set of default option values that are appropriate for many Rails applications.
# However it is highly customizable and can be used outside of Rails provided an appropriately
# designed model class.

class ScheduleTimer::Timer

	##
	# *model_class*
	#
	# The class that you pass into Timer as model_class is your interface to the Timer. It provides start and end dates,
	# start and end times, intervals, and actions to be performed when start, end, interval, and interrupt events take place.
	# At a minimum, this class must contain an attribute or method that returns a unique identifier (see Options[:id_field]),
	# at least one time-based trigger (i.e. start_time, interval, etc), and associated method handlers.
	#
	# The model_class is also responsible for loading instances of itself from the database, if you are loading from a database.
	# You can define the method names and parameters that make these calls. The defaults are designed around a Rails environment.
	#
	# model_class should implement some or all of the following methods or attribute readers to retrieve time-based triggers,
	# based on your use case.
	#
	# * *start_date* ⇒ Date: returns a Date object representing when this event should start, or nil for always (before end, if defined)
	# * *end_date* ⇒ Date: returns a Date object representing when this event should end, or nil for no end
	# * *start_time* ⇒ Time: returns a Time or DateTime object representing the time of day that this event should start, or nil for 00:00
	# * *end_time* ⇒ Time: returns a Time or DateTime object representing the time of day that this event should end, or nil for 00:00 the following day
	# * *interval* ⇒ Integer: returns an Integer representing the number of seconds between #on_interval method calls while active
	#
	# The following methods may be implemented in your model class, and will be called by the Timer as follows:
	#
	# * *on_start*: method called when start_time is reached (within start_date and end_date)
	# * *on_end*: method called when end_time is reached (within start_date and end_date)
	# * *on_interval*: method called once per interval during the active time (between start_time and end_time within start_date and end_date)
	# * *on_interrupt*: method called when the Timer is interrupted
	# * *on_tick*: method called on every tick
	#
	# ---
	#
	# *options*
	#
	# The options passed into Timer.new define how you want the Timer to operate. All keys should be Symbols.
	#
	# *Basics*
	# * *:id_field* (Symbol): (Default: :id) the unique identifying attribute of a model_class instance. This attribute reader or method must exist on your model class objects and return a unique identifier that can be used as a hash key.
	#
	# *Timing*
	#
	# * *:tick_interval* (Integer): (Default: 60) how frequently, in seconds, to check if events have started or ended. Lower values are more expensive.
	# * *:sync_to* (Symbol): if defined, wait to start Timer until the next minute, hour, or day. Allowed values: :minute, :hour, :day
	# * *:tick_before_sync* (Boolean): (Default: false) if true, Timer will tick once before waiting to sync as defined by :sync_to. Noop if :sync_to is not defined
	# * *:skip_first* (Boolean): (Default: false) if true, Timer will skip the first tick after it's started. Otherwise, it will tick immediately after starting (or after sync)
	# * *:use_time_date* (Boolean): (Default: false) if true, Timer will consider the date portion of a Time or DateTime object returned by ModelClass#start_time and/or #end_time when checking whether an event has started or ended. If false, normalizes the dates and only compares time of day.
	#
	# *Database*
	#
	# * *:autoload* (Boolean): (Default: true) set to false if you don't want the model_class to attempt to load instances of itself from your database.
	# * *:all_method* (String, Symbol): (Defualt: :all) the method name that should be called on model_class if no filter is supplied. Typically this would retrieve all instances of model_class.
	# * *:filter_method* (String, Symbol): (Default: :where) the method name that should be called on model_class if a filter is supplied. The filter will be passed as an argument.
	# * *:additional_events* (Object): an array of instances of compliant classes to be added to the Timer after ModelClass is loaded from the database.
	#
	# *Filters*
	#
	# Filters are processed in the order below. If a filter higher on this list is defined, ones below it will be ignored.
	#
	# * *:filter* (Array, Any): a custom filter or 2D Array of parameters to be sent to model_class.
	# * If this is an Array, it will be flattened and sent to model_class using the __send__ method. Therefore, the first element of the Array should be the method to call. Options[:filter_method] is not used. If this Array contains nested Arrays, they will be flattened and chained together. You can use this to create Active Record Query chains in Rails, such as ModelClass.join(:table).where('filter').
	# * If this is anything other than an Array, it will be sent to model_class.filter_method as-is.
	# * *:filter_sql* (String): SQL to be sent to filter_method. Can contain '?' placeholders for params.
	# * *:filter_params* (Array): params to be sent along with :filter_sql. Noop if :filter_sql is not defined.
	# * *:filter_hash* (Hash): A hash to be sent to model_class.filter_method.
	#
	# Both :filter_params and :filter_hash can contain the following Symbols, which will be replaced with date strings as follows:
	#
	# * :now: current date and time (formatted '%FT%T')
	# * :time: current time (formatted %T)
	# * :today: current date (formatted %F)
	#
	# *Logging*
	#
	# * *:name* (String, Symbol): a name used for logging. If created through the ScheduleTimer::new_timer method, this defaults to your timer name, unless specified in the options hash.
	# * *:logger* (Class): a class containing the methods debug, info, warn, error, and fatal to log events.
	#
	# @param model_class [Class] a Class containing attributes and methods necessary to interface with the Timer
	# @param options [Hash] a Hash of options to customize how the Timer operates
	def initialize(model_class, options = Hash.new)
		# Defaults
		@options = {
			:tick_interval => 60,
			:run_type => :toggle,
			:name => '',
			:filter_method => :where,
			:all_method => :all,
			:id_field => :id,
			:use_time_date => false
		}

		options.each do |k,v|
			@options[k] = v
		end

		raise ArgumentError.new('Missing or invalid model class') unless model_class
		raise ArgumentError.new('Invalid tick interval. Must be a number.') unless @options[:tick_interval].is_a? Numeric

		@options[:model] = model_class

		# Stores all relevant events and active events, respectively
		# Key is obj[@options[:id_field]], value is the object itself
		@events = Hash.new
		@active = Hash.new

		# Mutex memory barrier
		@mutex = Mutex.new
	end

	##
	# Starts the timer.
	# If options[:autoload] is true or nil, model instances will be loaded at this time.
	# If options[:sync_to] is defined, this will start the sync timer and then return.
	# If options[:tick_before_sync] is true, it will tick once immediately before starting the sync timer
	#
	# @return [Boolean] true if the timer (or sync timer) started successfully, else false
	def start()

		if @running || @wait_to_start
			if @options[:logger] then @options[:logger].warn('Timer#start was called, but this instance is already running or syncing. Doing nothing.') end
			return false
		end

		unless @options[:autoload] === false then refresh_from_db end

		if @options[:sync_to]
			if @options[:tick_before_sync] then tick(Time.now) end
			@wait_to_start = true
			@sync_thread = Thread.new do
				sync_clock(@options[:sync_to]) do
					if @wait_to_start then do_start end
				end
			end
		else
			do_start
		end

		true
	end

	##
	# Stops the Timer.
	#
	# @param interrupt [Boolean] if true, will kill the timer thread and call model_class.on_interrupt for each active model instance
	def stop(interrupt = false)
		ret = true
		if @wait_to_start
			@mutex.synchronize do
				@wait_to_start = false
			end
			if interrupt && @sync_thread && @sync_thread.status
				@sync_thread.kill
			end
		elsif interrupt && @timer_thread && @timer_thread.status
			@timer_thread.kill
		end

		@mutex.synchronize do
			@running = false
		end
		if interrupt
			@active.each do |k,v|
				model = @events[k]
				model.__send__(:on_interrupt) if defined?(model.on_interrupt)
			end
		end
		@active.clear
		true
	end

	##
	# Interrupts the Timer. Convenience method for Timer#stop(true)
	def interrupt
		stop(true)
	end

	##
	# Clears model instance list and refreshes from database
	#
	# @param filter [Array, Any] a filter to override options[:filter]
	def refresh_from_db(filter = nil)
		filter = filter || @options[:filter]
		models = []

		# Get instances from model class, applying filters if applicable
		if filter && filter.is_a?(Array)
			models = filter.inject(@options[:model]) do |relation, query|
				begin
					relation.__send__(query[0], *query[1..-1])
				rescue
					break;
				end
			end
		elsif filter
			@options[:model].__send__(@options[:filter_method], filter)
		elsif @options[:filter_sql]
			if @options[:filter_params]
				params = @options[:filter_params].map do |p|
					parse_time_symbols p
				end
				models = @options[:model].__send__(@options[:filter_method], @options[:filter_sql], *params)
			end
		elsif @options[:filter_hash]
			h = Hash.new
			@options[:filter_hash].each do |k, v|
				h[k] = parse_time_symbols v
			end
			models = @options[:model].__send__(@options[:filter_method], h)
		else
			models = @options[:model].__send__(@options[:all_method])
		end

		@events.clear

		# Re-enter additional events
		index = 1
		if @options[:additional_events].kind_of?(Array)
			@options[:additional_events].each do |e|
				key = defined?(e[@options[:id_field]]) ? e[@options[:id_field]] : "additional_event_#{index}"
				@events[key] = e
				index += 1
			end
		end

		# Push newly loaded models into @events
		if(!models.nil?)
			models.each do |m|
				@events[m[@options[:id_field]]] = m
			 	# unless @active[m[@options[:id_field]]]
			end
		end

		# Add reload event, if reload is requested
		if @options[:reload_at]
			r_event = ReloadEvent.new(self, @options[:reload_at])
			@events.push(r_event)
		end

	end

	##
	# Schedules a reload at the end of the current tick
	def schedule_reload
		@reload_scheduled = true
	end

	##
	# Adds an instance of Model to the Timer
	# This can be used to customize what is added, but may be reset if events are
	# re-loaded from the database
	#
	# @param new_event [Object] an instance of model_class to add
	def add_event(new_event)
		@mutex.synchronize do
			@events[new_event[@options[:id_field]]] = new_event
		end
	end

	##
	# Removes an event from the Timer
	#
	# @param r_event [Object] an instance of model_class to remove
	def remove_event(r_event)
		@mutex.sychronize do
			id = r_event[@options[:id_field]]
			if @active.include?(id)
				event.__send__ :on_interrupt
				@active.delete(id)
			end
			@events.remove(id)
		end
	end

	##
	# Gets loaded model instances
	#
	# @return An array of instances of ModelClass, plus any additional events
	def get_loaded_events
		@events
	end

	##
	# Gets model instances currently active
	#
	def get_active_events
		@active
	end

	##
	# Is the timer running?
	#
	def running?
		@running
	end

	private

	def do_start
		@wait_to_start = false
		@running = true
		timer_loop @options[:skip_first] ? @options[:skip_first] : false
	end

	def sync_clock(sync_to)
		now = Time.now
		case sync_to
			when :day
				t_time = now + 86400 - (now.hour * 3600) - (now.min * 60) - now.sec
			when :hour
				t_time = now + 3600 - (now.min * 60) - now.sec
			when :minute
				t_time = now + 60 - now.sec
			else
				t_time = now
		end
		if @options[:logger] then @options[:logger].info('Waiting ' + (t_time - now).round(2).to_s + ' seconds for timer sync. Timer ' + @options[:name] + ' will start at ' + t_time.to_s) end
		sleep(t_time - now)
		if block_given?
			yield
		else
			true
		end
	end

	def timer_loop(skip_first = false)
		@timer_thread = Thread.new do
			next_tick = @options[:tick_interval]
			while @running
				unless skip_first

					start = Time.now
					tick(start, next_tick)
					finish = Time.now
					t_diff = finish - start

					# If the tick took longer than an interval, log it and tick again immediately
					# Set the next tick to occur on time in order to re-sync
					if t_diff > next_tick
						if @options[:logger] then @options[:logger].info 'Timer ' + @options[:name] + ' tick took longer than tick interval. If this continues to happen, things will start running behind schedule.' end
						if @options[:logger] then @options[:logger].debug 'Timer ' + @options[:name] + ' tick took ' + t_diff.round(2).to_s + ' seconds. This is greater than the tick interval, ' + @options[:tick_interval].round(2).to_s + '. Ticking again immediately.' end
						tick(Time.now, t_diff)
						next_tick = calc_next_tick(t_diff)
						sleep(next_tick)
					else
						if @options[:logger] then @options[:logger].debug 'Timer ' + @options[:name] + ' tick took ' + t_diff.round(2).to_s + ' seconds. Ticking again in ' + (next_tick - t_diff).round(2).to_s + ' seconds.' end
						sleep(next_tick - t_diff)
					end
					next_tick = @options[:tick_interval]
				else
					sleep(next_tick)
					skip_first = false
				end
			end
		end
	end

	def tick(now, tick_time = @options[:tick_interval])

		if @options[:logger] then @options[:logger].debug 'Timer ' + @options[:name] + ' tick at ' + now.to_s end

		# Loop through events, parse dates/times
		# s_date/e_date = parse-able strings representing start and end dates, or nil for all dates
		# day = int or Array of ints representing the day(s) of the week, or nil for all days
		# s_time/e_time = Time, DateTime, or parse-able strings representing start and end times, or nil for midnight

		# Get a lock so @events and @active aren't messed with while we're working
		@mutex.synchronize do
			@events.each do |id, e|

				e.__send__(:on_tick) if defined?(e.on_tick)

				s_date = (defined?(e.start_date) && e.start_date.is_a?(Date)) ?	e.start_date : nil
				e_date = (defined?(e.end_date) && e.end_date.is_a?(Date)) ?	e.end_date : nil

				s_time = defined?(e.start_time) ? process_time(e.start_time, now) : Time.local(now.year, now.month, now.day, 0, 0, 0)
				e_time = defined?(e.end_time) ? process_time(e.end_time, now) : Time.local(now.year, now.month, now.day + 1, 0, 0, 0)

				day = (defined?(e.day) && (e.day.is_a?(Numeric) || e.day.is_a?(Array))) ? e.day : nil
				intrv = (defined?(e.interval) && e.interval.is_a?(Numeric)) ?	e.interval : (@options[:interval] ? @options[:inteval] : nil)

				# if (s_date.nil? || s_date <= now) && (e_date.nil? || e_date > now)
				# 	if day.nil? || day == now.day || (day.is_a?(Array) && day.include?(now.day))
				# 		if s_time <= now && e_time > now
				# 			if @active.include?(e[@options[:id_field]])
				# 				if @active[e[@options[:id_field]]]
				# 					@active[e[@options[:id_field]]] -= tick_time
				# 					if @active[e[@options[:id_field]]] <= 0
				# 						e.__send__(:on_interval) if defined?(e.on_interval)
				# 						@active[e[@options[:id_field]]] = intrv + @active[e[@options[:id_field]]]
				# 					end
				# 				end
				# 			else
				# 				e.__send__(:on_start) if defined?(e.on_start)
				# 				@active[e[@options[:id_field]]] = intrv || nil
				# 			end
				# 		elsif @active.include?(e[@options[:id_field]])
				# 			e.__send__(:on_end) if defined?(e.on_end)
				# 			@active.delete(e[@options[:id_field]])
				# 		end
				# 	end
				# end

				if @active.include?(e[@options[:id_field]])
					if (!e_date.nil? && e_date.to_time > now) ||
							(!day.nil? && ((day.is_a?(Array) && !day.include?(now.day)) || (day.is_a(Numeric) && day != now.day))) ||
							(e_time <= now)
						e.__send__(:on_end) if defined?(e.on_end)
						@active.delete([e[@options[:id_field]]])
					else
						if @active[e[@options[:id_field]]]
							@active[e[@options[:id_field]]] -= tick_time
							if @active[e[@options[:id_field]]] <= 0
								e.__send__(:on_interval) if defined?(e.on_interval)
								@active[e[@options[:id_field]]] = intrv + @active[e[@options[:id_field]]]
							end
						end
					end
				else
					if (s_date.nil? || s_date.to_time <= now) && (e_date.nil? || (e_date + 1).to_time >= now) &&
							(day.nil? || day == now.day || (day.is_a?(Array) && day.include?(now.day))) &&
							(s_time <= now && e_time > now)
						e.__send__(:on_start) if defined?(e.on_start)
						@active[e[@options[:id_field]]] = intrv || nil
					end
				end
			end
		end

		if @reload_scheduled
			refresh_from_db
			@reload_scheduled = false
		end
	end

	def process_time(time, now)
		s_time = time.is_a?(Time) ? time : (time.is_a?(DateTime) ? time.to_time : Time.parse(time))
		if !@options[:use_time_date]
			s_time = Time.local(now.year, now.month , now.day, s_time.hour, s_time.min, s_time.sec)
		end
	end

	def parse_time_symbols(val)
		case val
			when :now
				Time.now.strftime("%FT%T")
			when :time
				Time.now.strftime("%T")
			when :time_no_s
				Time.now.strftime("%R")
			when :today
				Date.today.strftime("%F")
			else
				val
		end
	end

	def calc_next_tick(t_diff)
		if(t_diff <= @options[:tick_interval])
			return t_diff
		end

		new_diff = (@options[:tick_interval] - (t_diff - @options[:tick_interval])).abs
		calc_next_tick(new_diff)
	end

end
