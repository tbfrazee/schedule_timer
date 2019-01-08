##
# ScheduleTimer is a Ruby module for implementing timed events with start and end times.
# It calls a specified method on your model class when each event starts, ends, or at
# regular intervals between start and end times. You define these times as attributes.
#
# These events can be extracted from a database (i.e. a Rails model) or defined manually.
#
# ScheduleTimer is written in Ruby and has no external dependencies.
# The default settings, however, are built with Rails models in mind, and it takes
# very little configuration to use this module in Rails.
#
# ScheduleTimer includes a set of module methods that behave as a manager,
# providing most commonly used functionality.
# These methods can create, start, stop, delete, and retrieve timers, and
# stores timers for easy management.
#
# If you'd like to manually manage your timers, you can instantiate a timer manually
# with ScheduleTimer::Timer#new.  See ScheduleTimer::Timer for more information.

module ScheduleTimer
	
	# @return [Hash] a hash [name, object] of all loaded timers.
	@@timers = Hash.new
	
	##
	# Creates a new timer and stores it for future reference.
	# If you create a timer this way, be sure to use ScheduleTimer.delete_timer when you're done with it.
	# Otherwise it will stay referenced here and may not be garbage collected.
	#
	# @param name [String, Symbol] a unique name for this timer
	# @param model [Class] the class that defines the timer's behavior. See {Timer#initialize}.
	# @param options [Hash] a hash of options to pass to the timer. See {Timer#initialize}.
	def self.new_timer(name, model, options = Hash.new)
		options[:name] = name.to_s unless options[:name]
		t = Timer.new(model, options)
		@@timers[name] = t
		t
	end
	
	##
	# Retrieves a stored timer object
	#
	# @param name [String, Symbol] the name of the timer to retrieve
	# @return [ScheduleTimer::Timer] the timer object
	def self.get_timer(name)
		@@timers[name]
	end
	
	##
	# Starts a stored timer
	#
	# @param name [String, Symbol] the name of the timer to start
	# @return [Boolean] true if timer successfully started, else false
	def self.start_timer(name)
		@@timers[name].start
	end
	
	##
	# Stops a stored timer
	#
	# @param name [String, Symbol] the name of the timer to stop
	# @return [Boolean] true if the timer successfully stopped, else false
	def self.stop_timer(name)
		@@timers[name].stop
	end
	
	##
	# Interrupts a stored timer
	# This is similar to ScheduleTimer::Stop, but calls the on_interrupt
	# method of each active model before stopping.
	#
	# @param name [String, Symbol] the name of the timer to interrupt
	# @return [Boolean] true if the timer successfully stopped, else false
	def self.interrupt_timer(name)
		@@timers[name].interrupt
	end
	
	##
	# Deletes a timer from storage, freeing it up for garbage collection
	# Interrupts the timer first, if it's still running
	#
	# @param name [String, Symbol] the name of the timer to delete
	# @return [Boolean] true if the timer successfully deleted, else false
	def self.delete_timer(name)
		@@timers[name].interrupt
		@@timers.delete(name)
	end
end

require 'schedule_timer/timer'