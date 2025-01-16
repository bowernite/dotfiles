#!/usr/bin/ruby
# <xbar.title>Countdown Timer</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Chris Yuen</xbar.author>
# <xbar.author.github>kizzx2</xbar.author.github>
# <xbar.desc>Simple countdown timer. Set the time by calling the script from terminal.</xbar.desc>
# <xbar.dependencies>ruby</xbar.dependencies>
# <xbar.image>https://raw.githubusercontent.com/kizzx2/bitbar-countdown-timer/master/screenshot.png</xbar.image>
# <xbar.abouturl>http://github.com/kizzx2/bitbar-countdown-timer</xbar.abouturl>

# NOTE: The above is the original plugin. I've made my own modifications. Also, note that that repository above doesn't seem to be fully updated to what you get when you actually install the plugin.

# Usage:
# countdown_timer.1s.rb [timer][,lockout]/[long_timer][,long_lockout] [task]
#
# Examples:
# countdown_timer.1s.rb 25m,5s            # 25min work, 5sec break
# countdown_timer.1s.rb 25m               # 25min work, default break
# countdown_timer.1s.rb 25m/90m           # 25min work + 90min long session
# countdown_timer.1s.rb 25m,5s/90m,15m    # Both timers with custom breaks
# countdown_timer.1s.rb meeting           # Default timer for meeting
# countdown_timer.1s.rb meeting/2h        # Meeting with 2hr hard stop

filename = File.join(File.dirname($0), '.countdown')

def hide_timer
  puts ""
  exit 0
end

def lock_screen
  system "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down, control down}'"
end

def sleep_screen
  system "pmset displaysleepnow"
end

def show_notification(title, message)
  system "osascript -e 'display notification \"#{message}\" with title \"#{title}\"'"
end

def parse_data_from_file(filename)
  if File.file?(filename)
    data = {}
    File.read(filename).each_line do |line|
      key, value = line.strip.split('=', 2)
      data[key] = value if key && value
    end

    finish_timestamp = Time.at(data['finish_timestamp'].to_i)
    long_finish_timestamp = data['long_finish_timestamp'] ? Time.at(data['long_finish_timestamp'].to_i) : nil
    task = data['task']
    locked_out_for = data['lockout_duration'].to_i if data['lockout_duration']
    long_locked_out_for = data['long_lockout_duration'].to_i if data['long_lockout_duration']
    [finish_timestamp, long_finish_timestamp, task, locked_out_for, long_locked_out_for]
  else
    [Time.at(0), nil, nil, nil, nil]
  end
end

def parse_duration(value, unit)
  unit ||= 'm' # Default to minutes if no unit specified
  case unit
    when 's' then value
    when 'm' then value * 60
    when 'h' then value * 3600
  end
end

def parse_args(args)
  # Default timer values
  default_timer = "25m"
  default_lockout = "5s"
  args = [default_timer + "," + default_lockout] if args.empty?

  case args.first
  when '-1', '0'
    [0, nil, nil, nil, nil]
  when /^(\d+)(s|m|h)?(,(\d+)(s|m|h)?)?(\/((\d+)(s|m|h)?(,(\d+)(s|m|h)?)?)?)?$/
    # Capture all regex matches before any further processing
    timer_value = $1
    timer_unit = $2
    lockout_value = $4
    lockout_unit = $5
    long_timer_value = $8
    long_timer_unit = $9
    long_lockout_value = $11
    long_lockout_unit = $12
    
    # Parse timer value if provided, otherwise use default
    timer_value = timer_value ? timer_value.to_i : default_timer[/\d+/].to_i
    timer_unit = timer_unit || default_timer[/[smh]/]
    timer_seconds = parse_duration(timer_value, timer_unit)
    finish_timestamp = Time.now + timer_seconds + 2

    # Parse optional lockout duration
    lockout_seconds = if lockout_value
      lockout_value = lockout_value.to_i
      lockout_unit = lockout_unit || default_lockout[/[smh]/]
      parse_duration(lockout_value, lockout_unit)
    else
      # Use default lockout when not specified
      lockout_value = default_lockout[/\d+/].to_i
      lockout_unit = default_lockout[/[smh]/]
      parse_duration(lockout_value, lockout_unit)
    end

    # Parse optional long timer and lockout
    long_finish_timestamp = nil
    long_lockout_seconds = nil
    if long_timer_value
      long_timer_value = long_timer_value.to_i
      long_timer_unit = long_timer_unit || 'm'
      long_timer_seconds = parse_duration(long_timer_value, long_timer_unit)
      long_finish_timestamp = Time.now + long_timer_seconds + 2

      if long_lockout_value
        long_lockout_value = long_lockout_value.to_i
        long_lockout_unit = long_lockout_unit || 'm'
        long_lockout_seconds = parse_duration(long_lockout_value, long_lockout_unit)
      end
    end

    task = args.count > 1 ? args.drop(1).join(' ') : nil
    [finish_timestamp, long_finish_timestamp, lockout_seconds, long_lockout_seconds, task]
  else
    # First arg must be task name - use default timer and lockout
    timer_value = default_timer[/\d+/].to_i
    timer_unit = default_timer[/[smh]/]
    timer_seconds = parse_duration(timer_value, timer_unit)
    finish_timestamp = Time.now + timer_seconds + 2

    lockout_value = default_lockout[/\d+/].to_i
    lockout_unit = default_lockout[/[smh]/]
    lockout_seconds = parse_duration(lockout_value, lockout_unit)
    
    # Check if task has a long timer specified
    task_parts = args.first.split('/')
    long_finish_timestamp = nil
    long_lockout_seconds = nil
    
    if task_parts.length > 1 && task_parts[1] =~ /^(\d+)(s|m|h)?$/
      long_timer_value = $1.to_i
      long_timer_unit = $2 || 'm'
      long_timer_seconds = parse_duration(long_timer_value, long_timer_unit)
      long_finish_timestamp = Time.now + long_timer_seconds + 2
    end
    
    [finish_timestamp, long_finish_timestamp, lockout_seconds, long_lockout_seconds, task_parts[0]]
  end
end

# This is just a refresh, not a new instance of a timer
is_refresh = ARGV.count == 0
if is_refresh
  task = nil
  locked_out_for = nil
  long_locked_out_for = nil

  finish_timestamp, long_finish_timestamp, task, locked_out_for, long_locked_out_for = parse_data_from_file(filename)

  seconds_remaining = (finish_timestamp - Time.now).to_i
  long_seconds_remaining = long_finish_timestamp ? (long_finish_timestamp - Time.now).to_i : nil
  
  if seconds_remaining == 300
    show_notification("5 minutes remaining! ⚠️", "#{task || "Timer"}")
  end
  if seconds_remaining == 120
    show_notification("2 minutes remaining! ⚠️", "#{task || "Timer"}")
  end

  if seconds_remaining == 0
    lock_screen
    
    # Keep the user locked out for a while
    end_time = Time.now + locked_out_for
    while Time.now <= end_time
      lock_screen
      sleep 2 # Keep checking on an interval
    end
  end

  if long_seconds_remaining && long_seconds_remaining == 0
    lock_screen
    
    if long_locked_out_for
      end_time = Time.now + long_locked_out_for
      while Time.now <= end_time
        lock_screen
        sleep 2
      end
    end
  end

  if seconds_remaining < 0 && (!long_seconds_remaining || long_seconds_remaining < 0)
    hide_timer
  end

  seconds_remaining = 0 if seconds_remaining < 0
  long_seconds_remaining = 0 if long_seconds_remaining && long_seconds_remaining < 0

  def format_time(seconds)
    h = seconds / 3600
    seconds -= h * 3600
    m = seconds / 60
    seconds -= m * 60
    s = seconds

    if h > 0
      "%02i:%02i:%02i" % [h, m, s]
    else
      "%02i:%02i" % [m, s]
    end
  end

  str = ""
  str << "#{task}: " if task
  str << format_time(seconds_remaining)
  str << " | #{format_time(long_seconds_remaining)}" if long_seconds_remaining

  emoji = nil
  if seconds_remaining < 2 * 60 && seconds_remaining != 0
    emoji = "🔴"
  elsif seconds_remaining < 5 * 60 && seconds_remaining != 0
    emoji = "🟡"
  end

  str << " #{emoji}" if emoji

  puts str

  # Adds menu bar item to cancel the timer
  puts "---\nCancel Timer | bash=#{__FILE__} param1=-1 terminal=false"

# This is a new instance of a timer
else
  finish_timestamp, long_finish_timestamp, lockout_seconds, long_lockout_seconds, task = parse_args(ARGV)

  data = []
  data << "finish_timestamp=#{finish_timestamp.to_i}"
  data << "long_finish_timestamp=#{long_finish_timestamp.to_i}" if long_finish_timestamp
  data << "lockout_duration=#{lockout_seconds}" if lockout_seconds
  data << "long_lockout_duration=#{long_lockout_seconds}" if long_lockout_seconds
  data << "task=#{task}" if task

  File.write(filename, data.join("\n"))
end
