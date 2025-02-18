require 'net/http'

class Url
  def initialize(address)
    @uri = URI(address)
  end

  def path
    return '/' if @uri.path.empty?
    @uri.path
  end

  def to_s
    "#{scheme}://#{host}:#{port}#{path}"
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
      puts "#{@url} -> #{res.code} #{res.message}"
      sleep 2
    rescue Errno::ECONNREFUSED
      puts "#{@url} -> Connection refused"
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
