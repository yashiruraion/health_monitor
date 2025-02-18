require 'net/http'

class Url
  def initialize(address)
    @uri = URI(address)
  end

  def path
    return '/' if @uri.path.empty?
    @uri.path
  end

  def method_missing(name, *args, &block)
    @uri.send(name, *args, &block)
  end
end

class App
  def initialize(url)
    @url = url
  end

  def start
    req = Net::HTTP.new(@url.host, @url.port)
    req.open_timeout = 5

    loop do
      res = req.get @url.path
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
  url = Url.new(ARGV[0])
  App.new(url).start
else
  puts "ruby #{$0} [url]"
end
