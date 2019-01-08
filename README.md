# ScheduleTimer

ScheduleTimer is a Ruby module for implementing timed events with start and end times. It calls a specified method on your model class when each event starts, ends, or at regular intervals between start and end times. You define these times as attributes.

These events can be extracted from a database (i.e. a Rails model) or defined manually.

ScheduleTimer is written in Ruby and has no external dependencies. The default settings, however, are built with Rails models in mind, and it takes very little configuration to use this module in Rails.

The ScheduleTimer module includes a set of module methods behaves as a manager, providing most commonly used functionality. These methods can create, start, stop, delete, and retrieve timers, and stores timers for easy management.  If you'd like to manually manage your timers, you can access the ScheduleTimer::Timer class directly.

## ScheduleTimer Module Methods

```ruby
options = { :sync_to => :hour, :filter => { :name => 'Bob' }, :logger => Rails.logger }
timer = ScheduleTimer.new_timer :timer_name, ModelClass, options
ScheduleTimer.start_timer :timer_name
```

### #new_timer(name, model, options) ⇒ ScheduleTimer::Timer
Creates a new timer and stores it for future reference.
* Param `name` (Symbol, String): A unique identifier for this Timer.
* Param `model` (Class): The Class that defines methods and attributes for ScheduleTimer to call. See [Model Class](#model-class) for more information.
* *Optional* Param `options` (Hash): A Hash of options to customize the behavior of ScheduleTimer. See [Timer Options](#timer-options) for more information.
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
## Model Class

The class that you pass into ScheduleTimer.new_timer or ScheduleTimer::Timer.new is your interface to the Timer. It provides start and end dates, start and end times, intervals, and actions to be performed when start, end, interval, and interrupt events take place. At a minimum, this class must contain an attribute or method that returns a unique identifier (see [Timer Options](#timer-options)), at least one time-based trigger (i.e. start_time, interval, etc), and associated method handlers.

The model class is also responsible for loading instances of itself from the database, if you are loading from a database. ScheduleTimer will attempt to load these instances from the model class itself. You can define the method names and parameters that make these calls. The defaults are designed around a Rails environment.

Your model class should implement some or all of the following methods or attribute readers to retrieve time-based triggers, based on your use case.

### start_date ⇒ Date
Returns a Date object representing when this event should start, or nil for always (before end, if defined).

### end_date ⇒ Date
Returns a Date object representing when this event should end, or nil for no end.

### start_time ⇒ Time
Returns a Time object representing the time of day that this event should start, or nil for 00:00

### end_time ⇒ Time
Returns a Time object representing the time of day that this event should end, or nil for 00:00 the following day

### interval ⇒ Integer
Returns an Integer representing the number of seconds between ::on_interval method calls while active

The following methods may be implemented in your model class, and will be called by the Timer as follows:

### on_start
Method called when start_time is reached (within start_date and end_date)

### on_end
Method called when end_time is reached (within start_date and end_date)

### on_interval
Method called once per interval during the active time (between start_time and end_time within start_date and end_date)

### on_interrupt
Method called when the Timer is interrupted

## Timer Options

Options are even doper, dawg.
