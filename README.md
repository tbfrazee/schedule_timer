# ScheduleTimer
---
ScheduleTimer is a Ruby module for implementing timed events with start and end times. It calls a specified method on your model class when each event starts, ends, or at regular intervals between start and end times. You define these times as attributes.

These events can be extracted from a database (i.e. a Rails model) or defined manually.

ScheduleTimer is written in Ruby and has no external dependencies. The default settings, however, are built with Rails models in mind, and it takes very little configuration to use this module in Rails.

ScheduleTimer includes a set of module methods that behave as a manager, providing most commonly used functionality. These methods can create, start, stop, delete, and retrieve timers, and stores timers for easy management.

If you'd like to manually manage your timers, you can instantiate a timer manually with ScheduleTimer::Timer#new. See ScheduleTimer::Timer for more information.

## ScheduleTimer Class Method Summary
    #delete_timer(name) ⇒ Boolean
Deletes a timer from storage, freeing it up for garbage collection Interrupts the timer first, if it's still running.
    #get_timer(name) ⇒ ScheduleTimer::Timer
Retrieves a stored timer object.
    #interrupt_timer(name) ⇒ Boolean
Interrupts a stored timer This is similar to ScheduleTimer::Stop, but calls the on_interrupt method of each active model before stopping.
    #new_timer(name, model, options = Hash.new) ⇒ Object
Creates a new timer and stores it for future reference.
    #start_timer(name) ⇒ Boolean
Starts a stored timer.
    #stop_timer(name) ⇒ Boolean
Stops a stored timer.

Class Method Details
.delete_timer(name) ⇒ Boolean
Deletes a timer from storage, freeing it up for garbage collection Interrupts the timer first, if it's still running

Parameters:

name (String, Symbol) — the name of the timer to delete
Returns:

(Boolean) — true if the timer successfully deleted, else false
[View source]
.get_timer(name) ⇒ ScheduleTimer::Timer
Retrieves a stored timer object

Parameters:

name (String, Symbol) — the name of the timer to retrieve
Returns:

(ScheduleTimer::Timer) — the timer object
[View source]
.interrupt_timer(name) ⇒ Boolean
Interrupts a stored timer This is similar to ScheduleTimer::Stop, but calls the on_interrupt method of each active model before stopping.

Parameters:

name (String, Symbol) — the name of the timer to interrupt
Returns:

(Boolean) — true if the timer successfully stopped, else false
[View source]
.new_timer(name, model, options = Hash.new) ⇒ Object
Creates a new timer and stores it for future reference. If you create a timer this way, be sure to use ScheduleTimer.delete_timer when you're done with it. Otherwise it will stay referenced here and may not be garbage collected.

Parameters:

name (String, Symbol) — a unique name for this timer
model (Class) — the class that defines the timer's behavior. See ScheduleTimer::Timer#initialize.
options (Hash) (defaults to: Hash.new) — a hash of options to pass to the timer. See ScheduleTimer::Timer#initialize.
[View source]
.start_timer(name) ⇒ Boolean
Starts a stored timer

Parameters:

name (String, Symbol) — the name of the timer to start
Returns:

(Boolean) — true if timer successfully started, else false
[View source]
.stop_timer(name) ⇒ Boolean
Stops a stored timer

Parameters:

name (String, Symbol) — the name of the timer to stop
Returns:

(Boolean) — true if the timer successfully stopped, else false
[View source]