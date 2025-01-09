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

# This is just a refresh, not a new instance of a timer
is_refresh = ARGV.count == 0
if is_refresh
  task = nil
  locked_out_for = nil

  if File.file?(filename)
    data = {}
    File.read(filename).each_line do |line|
      key, value = line.strip.split('=', 2)
      data[key] = value if key && value
    end

    finish_timestamp = Time.at(data['finish_timestamp'].to_i)
    task = data['task']
    locked_out_for = data['lockout_duration'].to_i if data['lockout_duration']
  else
    finish_timestamp = Time.at(0)
  end

  seconds_remaining = (finish_timestamp - Time.now).to_i
  
  # TODO: Move back to being 120s. This is just for testing.
  if seconds_remaining == 120
    system %(osascript -e 'display notification "2 minutes remaining! ⚠️" with title "#{task || "Timer"}"')
  end

  if seconds_remaining == 0
    # system %(osascript -e 'display notification "Time\'s up!" with title "Time\'s up!" sound name "Glass"')

    lock_screen
    
    # Keep the user locked out for a while
    locked_out_for ||= 5 # Default to 5 seconds if not specified
    end_time = Time.now + locked_out_for
    while Time.now <= end_time
      lock_screen
      sleep 2 # Keep checking on an interval
    end
  end
  if seconds_remaining < 0
    hide_timer
  end

  seconds_remaining = 0 if seconds_remaining < 0

  emoji = nil

  if seconds_remaining < 2 * 60 && seconds_remaining != 0
    emoji = "🔴"
  elsif seconds_remaining < 5 * 60 && seconds_remaining != 0
    emoji = "🟡"
  end

  h = seconds_remaining / 3600
  seconds_remaining -= h * 3600

  m = seconds_remaining / 60
  seconds_remaining -= m * 60

  s = seconds_remaining

  str = ""
  str << "#{task}: " if task
  if h > 0
    str << "%02i:%02i:%02i" % [h, m, s]
  else
    str << "%02i:%02i" % [m, s]
  end
  str << " #{emoji}" if emoji

  puts str

  # Adds menu bar item to cancel the timer
  puts "---\nCancel Timer | bash=#{__FILE__} param1=-1 terminal=false"

# This is a new instance of a timer
else
  case ARGV.first
  when '-1'
    finish_timestamp = 0
  when '0'
    finish_timestamp = 0
  when /^(\d+)(s|m|h)?(,(\d+)(s|m|h)?)?$/
    # Parse timer duration
    timer_value = $1.to_i
    timer_unit = $2 || 'm' # Default to minutes if no unit specified
    
    timer_seconds = case timer_unit
      when 's' then timer_value
      when 'm' then timer_value * 60
      when 'h' then timer_value * 3600
    end
    
    finish_timestamp = Time.now + timer_seconds
    
    # Parse optional lockout duration
    # ($3 is the entire match, including the comma)
    lockout_seconds = if $4 
      lockout_value = $4.to_i
      lockout_unit = $5 || 'm' # Default to minutes if no unit specified
      
      case lockout_unit
        when 's' then lockout_value
        when 'm' then lockout_value * 60
        when 'h' then lockout_value * 3600
      end
    end
  else
    puts "Error: Invalid argument '#{ARGV.first}'"
    exit 1
  end

  data = []
  data << "finish_timestamp=#{finish_timestamp.to_i}"
  data << "lockout_duration=#{lockout_seconds}" if lockout_seconds
  
  # Add task if provided
  if ARGV.count > 1
    task = ARGV.drop(1).join(' ')
    data << "task=#{task}"
  end

  File.write(filename, data.join("\n"))
end
