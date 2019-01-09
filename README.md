# ScheduleTimer

ScheduleTimer is a Ruby module for implementing recurring calendar events with start and end times. You supply a class that defines start, end, and/or time interval values as well as  methods to be called when these events occur (a Rails model works well). ScheduleTimer loads instances of this class from your database (or you can add them manually) and waits for the first event to start.

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

**start_date ⇒ Date**

Returns a Date object representing when this event should start, or nil for always (before end, if defined).

**end_date ⇒ Date**

Returns a Date object representing when this event should end, or nil for no end.

**start_time ⇒ Time**

Returns a Time object representing the time of day that this event should start, or nil for 00:00

**end_time ⇒ Time**

Returns a Time object representing the time of day that this event should end, or nil for 00:00 the following day. If start_time and end_time overlap, neither #on_start nor @on_end will be called. This way, you can cross midnight without triggering event method calls.

**interval ⇒ Integer**

Returns an Integer representing the number of seconds between ::on_interval method calls while active

---
Additionally, the following methods may be implemented in your model class, and will be called by the Timer as follows:

**on_start**

Method called when start_time is reached (within start_date and end_date)

**on_end**

Method called when end_time is reached (within start_date and end_date)

**on_interval**

Method called once per interval during the active time (between start_time and end_time within start_date and end_date)

**on_interrupt**

Method called when the Timer is interrupted

## Timer Options

The options passed into Timer.new define how you want the Timer to operate. All keys should be Symbols.

### Basics

**:id_field** (Symbol): (Default: :id) the unique identifying attribute of a model_class instance. This attribute reader or method must exist on your model class objects and return a unique identifier that can be used as a hash key.

### Timing

**:tick_interval** (Integer): (Default: 60) how frequently, in seconds, to check if events have started or ended. Lower values are more expensive.

**:sync_to** (Symbol): if defined, wait to start Timer until the next minute, hour, or day. Allowed values: :minute, :hour, :day

**:tick_before_sync** (Boolean): if true, Timer will tick once before waiting to sync as defined by :sync_to. Noop if :sync_to is not defined

**:skip_first** (Boolean): if true, Timer will skip the first tick after it's started. Otherwise, it will tick immediately after starting (or after sync)

### Database

**:autoload** (Boolean): (Default: true) set to false if you don't want the model_class to attempt to load instances of itself from your database.

**:all_method** (String, Symbol): (Defualt: :all) the method name that should be called on model_class to get instances from the database if no filter is supplied. This is called without arguments. Typically this would retrieve all instances of model_class.

**:filter_method** (String, Symbol): (Default: :where) the method name that should be called on model_class to get instances from the database if a filter is supplied. The filter ([below])(#filters) will be passed as an argument.

### Filters

Filters are processed in the order below. If a filter higher on this list is defined, ones below it will be ignored.

**:filter** (Array, Any): a custom filter or 2D Array of parameters to be sent to model_class.

If this is an Array, it will be flattened and sent to model_class using the `__send__` method. Therefore, the first element of the Array should be the method to call. Options\[:filter_method] is not used. If this Array contains nested Arrays, they will be flattened and chained together. You can use this to create Active Record Query chains in Rails, i.e.:

```ruby
[
    [ 'joins', :table ],
    [ 'where', { :name => 'Bob' ]
]
```

...will generate the query:

```ruby
ModelClass.join(:table).where('filter')
```

If this is anything other than an Array, it will be sent to model_class.filter_method as-is.

**:filter_sql** (String): SQL to be sent to filter_method. Can contain '?' placeholders for params.

**:filter_params** (Array): params to be sent along with :filter_sql. Noop if :filter_sql is not defined.

**:filter_hash** (Hash): A hash to be sent to model_class.filter_method.

Both :filter_params and :filter_hash can contain the following Symbols as values, which will be replaced with date strings as follows:

* :now: current date and time (formatted '%FT%T')
* :time: current time (formatted %T)
* :today: current date (formatted %F)

### Logging

**:name** (String, Symbol): a name used for logging. If created through the ScheduleTimer.new_timer method, this defaults to your timer name, unless specified in the options hash.

**:logger** (Class): a class containing the methods debug, info, warn, error, and fatal to log events.

## TODO
* Implement automated scheduled reloads from database
* Clean up interpretation of `Time` instances so that they ignore the embedded date value
