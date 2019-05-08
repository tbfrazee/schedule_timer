Gem::Specification.new do |s|
	s.name = 'schedule_timer'
	s.version = '0.2.1'
	s.summary = 'A timer that handles event start, end, and interval calls.'
	s.description = 'ScheduleTimer is a cron-less timer gem designed to work with calendar events with start and end dates and/or times, triggering method calls at these times.'
	s.author = 'Tim Frazee'
	s.files = ['lib/schedule_timer.rb', 'lib/schedule_timer/timer.rb', 'lib/schedule_timer/reload_event.rb']
	s.homepage = 'http://rubygems.org/gems/schedule_timer'
	s.license = 'MIT'
	s.add_development_dependency "rspec"
	s.add_development_dependency "byebug"
end
