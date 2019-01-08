# ScheduleTimer

ScheduleTimer is a Ruby module for implementing timed events with start and end times. It calls a specified method on your model class when each event starts, ends, or at regular intervals between start and end times. You define these times as attributes.

These events can be extracted from a database (i.e. a Rails model) or defined manually.

ScheduleTimer is written in Ruby and has no external dependencies. The default settings, however, are built with Rails models in mind, and it takes very little configuration to use this module in Rails.

ScheduleTimer includes a set of module methods that behave as a manager, providing most commonly used functionality. These methods can create, start, stop, delete, and retrieve timers, and stores timers for easy management.

If you'd like to manually manage your timers, you can instantiate a timer manually with ScheduleTimer::Timer#new. See ScheduleTimer::Timer for more information.

## ScheduleTimer Module Methods
### #new_timer(name, model, options) ⇒ ScheduleTimer::Timer
Creates a new timer and stores it for future reference.
* Param `name` (Symbol, String): A unique identifier for this Timer.
* Param `model` (Class): The Class that defines methods and attributes for ScheduleTimer to call.
* *Optional* Param `options` (Hash): A Hash of options to customize the behavior of ScheduleTimer.
* Return (ScheduleTimer::Timer): The resulting Timer object.

```ruby
options = { :sync_to => :hour, :filter => { :name => 'Bob' }, :logger => Rails.logger }
timer = ScheduleTimer.new_timer :timer_name, ModelClass, options
```
    
### #get_timer(name) ⇒ ScheduleTimer::Timer
Retrieves a stored timer object.
* Param `name` (Symbol, String): The unique identifier of the Timer you want to retrieve.
* Return (ScheduleTimer::Timer): The requested Timer object, or nil.

```ruby
timer = ScheduleTimer.get_timer :timer_name
```

### #start_timer(name) ⇒ Boolean
Starts a stored timer.
* Param `name` (Symbol, String): The unique identifier of the Timer you'd like to start.
* Return (Boolean): true if the Timer started successfully, else false.

```ruby
ScheduleTimer.start_timer :timer_name
```

### #stop_timer(name) ⇒ Boolean
Stops a stored timer.
* Param `name` (Symbol, String): The unique identifier of the Timer you'd like to stop.
* Return (Boolean): true if the Timer stopped successfully, else false.

```ruby
ScheduleTimer.stop_timer :timer_name
```

### #interrupt_timer(name) ⇒ Boolean
Interrupts a stored timer This is similar to ScheduleTimer::Stop, but calls the on_interrupt method of each active model before stopping.
* Param `name` (Symbol, String): The unique identifier of the Timer you'd like to interrupt.
* Return (Boolean): true if the Timer was interrupted successfully, else false.

```ruby
ScheduleTimer.interrupt_timer :timer_name
```

### #delete_timer(name) ⇒ Boolean
Deletes a timer from storage, freeing it up for garbage collection Interrupts the timer first, if it's still running.
* Param `name` (Symbol, String): The unique identifier of the Timer you'd like to delete
* Return (Boolean): true if the Timer was successfully deleted, else false.

```ruby
ScheduleTimer.delete_timer :timer_name
```
