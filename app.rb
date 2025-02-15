require 'net/http'

class App
  def initialize(url)
    @uri = URI(url)
  end

  def host
    @uri.host
  end

  def port
    @uri.port
  end

  def path
    return '/' if @uri.path.empty?
    @uri.path
  end

  def start
    req = Net::HTTP.new(host, port)
    req.open_timeout = 5

    loop do
      res = req.get path
      if res.code == '200'
        puts 'healthy'
      else
        puts 'not healthy'
      end
      sleep 2
    rescue Errno::ECONNREFUSED
      puts 'retrying...'
      sleep 2
    end

  rescue Interrupt
    puts
  end
end

if ARGV.size == 1
  App.new(ARGV[0]).start
else
  puts "ruby #{$0} [url]"
end
