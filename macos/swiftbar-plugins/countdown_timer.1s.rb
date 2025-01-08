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

fn = File.join(File.dirname($0), '.countdown')

def hide_timer
  puts ""
  exit 0
end

# This is just a refresh, not a new instance of a timer
is_refresh = ARGV.count == 0
if is_refresh
  task = nil

  if File.file?(fn)
    lines = File.read(fn).lines

    finish_timestamp = Time.at(lines.first.to_i)
    task = lines[1] if lines.count > 1
  else
    finish_timestamp = Time.at(0)
  end

  seconds_remaining = finish_timestamp - Time.now
  
  # TODO: Move back to being 120s. This is just for testing.
  if seconds_remaining.to_i == 5
    system %(osascript -e 'display notification "2 minutes remaining! ⚠️" with title "#{task || "Timer"}"')
  end

  if seconds_remaining.to_i == 0
    # system %(osascript -e 'display notification "Time\'s up!" with title "Time\'s up!" sound name "Glass"')
    system %(pmset displaysleepnow)
  end
  # if seconds_remaining.to_i <= 0
  #   hide_timer
  # end

  seconds_remaining = 0 if seconds_remaining < 0

  emoji = nil

  if seconds_remaining < 2 * 60 && seconds_remaining != 0
    emoji = "🔴"
  elsif seconds_remaining < 5 * 60 && seconds_remaining != 0
    emoji = "🟡"
  end

  h = (seconds_remaining / 3600).to_i
  seconds_remaining -= h * 3600

  m = (seconds_remaining / 60).to_i
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
  puts "---\nCancel Timer | bash=#{__FILE__} param1=0 terminal=false"

# This is a new instance of a timer
else
  case ARGV.first
  when '0'
    finish_timestamp = 0
  when /^(\d+)s$/
    finish_timestamp = Time.now + $1.to_i
  when /^(\d+)m$/
    finish_timestamp = Time.now + $1.to_i * 60
  when /^(\d+)h$/
    finish_timestamp = Time.now + $1.to_i * 3600
  else
    puts "Error: Invalid argument '#{ARGV.first}'"
    exit 1
  end

  str = ""
  str << finish_timestamp.to_i.to_s

  if ARGV.count > 1
    str << "\n"
    str << ARGV.drop(1).join(' ')
  end

  File.write(fn, str)
end
