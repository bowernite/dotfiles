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

filename = File.join(File.dirname($0), '.countdown')

def end_timer
  puts ""
  # puts "⚠️ 0:00 | color=yellow"
  exit 0
end

def lock_screen
  system "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down, control down}'"
end

def sleep_screen
  system "pmset displaysleepnow"
end

def show_macos_notification(title, message)
  # Show standard macOS notification
  system "osascript -e 'display notification \"#{message || "Timer"}\" with title \"#{title}\"'"
end

def show_hammerspoon_alert(title, message, duration)
  # Show Hammerspoon alert
  alert_message = message && !message.empty? ? "#{title}: #{message}" : title
  alert_message = alert_message.gsub('"', '\\"') # Escape double quotes for shell and Lua
  system "hs -c \"hs.alert.show('#{alert_message}', #{duration})\""
end

def parse_data_from_file(filename)
  if File.file?(filename)
    data = {}
    File.read(filename).each_line do |line|
      key, value = line.strip.split('=', 2)
      data[key] = value if key && value
    end

    finish_timestamp = Time.at(data['finish_timestamp'].to_i)
    task = data['task']
    locked_out_for = data['lockout_duration'].to_i if data['lockout_duration']
    [finish_timestamp, task, locked_out_for]
  else
    [Time.at(0), nil, nil]
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
  default_lockout = "90s"
  args = [default_timer + "," + default_lockout] if args.empty? or args.first == "RESET_TIMER"

  case args.first
  when '-1', '0'
    [0, nil, nil]
  when /^(\d+)(s|m|h)?(,(\d+)(s|m|h)?)?$/
    # Capture all regex matches before any further processing
    timer_value = $1
    timer_unit = $2
    lockout_value = $4
    lockout_unit = $5
    
    # Parse timer value if provided, otherwise use default
    timer_value = timer_value ? timer_value.to_i : default_timer[/\d+/].to_i
    timer_unit = timer_unit || default_timer[/[smh]/]
    timer_seconds = parse_duration(timer_value, timer_unit)
    # Add an extra second, to account for delay in SwiftBar actually showing the timer
    finish_timestamp = Time.now + timer_seconds + 1

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

    task = args.count > 1 ? args.drop(1).join(' ') : nil
    [finish_timestamp, lockout_seconds, task]
  else
    # First arg must be task name - use default timer and lockout
    timer_value = default_timer[/\d+/].to_i
    timer_unit = default_timer[/[smh]/]
    timer_seconds = parse_duration(timer_value, timer_unit)
    finish_timestamp = Time.now + timer_seconds + 2

    lockout_value = default_lockout[/\d+/].to_i
    lockout_unit = default_lockout[/[smh]/]
    lockout_seconds = parse_duration(lockout_value, lockout_unit)
    
    [finish_timestamp, lockout_seconds, args.join(' ')]
  end
end

# This is just a refresh, not a new instance of a timer
is_refresh = ARGV.count == 0
if is_refresh
  task = nil
  locked_out_for = nil

  finish_timestamp, task, locked_out_for = parse_data_from_file(filename)

  seconds_remaining = (finish_timestamp - Time.now).to_i
  
  if seconds_remaining == 300
    title = "5 minutes remaining! ⚠️"
    message = task
    # show_macos_notification(title, message)
    show_hammerspoon_alert(title, message, 5)
  end
  if seconds_remaining == 120
    title = "2 minutes remaining! ⚠️"
    message = task
    # show_macos_notification(title, message)
    show_hammerspoon_alert(title, message, 10)
  end

  if seconds_remaining == 0
    # show_notification("Time's up!", "Time's up!")

    lock_screen
    
    # Keep the user locked out for a while
    end_time = Time.now + locked_out_for
    while Time.now <= end_time
      lock_screen
      sleep 2 # Keep checking on an interval
    end
  end
  if seconds_remaining < 0
    end_timer
  end

  seconds_remaining = 0 if seconds_remaining < 0

  seconds_decremented = seconds_remaining
  
  h = seconds_decremented / 3600
  seconds_decremented -= h * 3600

  m = seconds_decremented / 60
  seconds_decremented -= m * 60

  s = seconds_decremented

  str = ""
  str << "#{task}: " if task
  if h > 0
    str << "%02i:%02i:%02i" % [h, m, s]
  else
    str << "%02i:%02i" % [m, s]
  end

  emoji = nil
  if seconds_remaining < 2 * 60 && seconds_remaining != 0
    emoji = "🔴"
  elsif seconds_remaining < 5 * 60 && seconds_remaining != 0
    emoji = "🟡"
  end

  str << " #{emoji}" if emoji

  puts str

  # Adds menu bar item to reset the timer
  puts "---\nReset Timer | bash=#{__FILE__} param1=\"RESET_TIMER\" terminal=false"

# This is a new instance of a timer
else
  finish_timestamp, lockout_seconds, task = parse_args(ARGV)

  data = []
  data << "finish_timestamp=#{finish_timestamp.to_i}"
  data << "lockout_duration=#{lockout_seconds}" if lockout_seconds
  data << "task=#{task}" if task

  File.write(filename, data.join("\n"))
end
