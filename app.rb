require 'net/http'

module HealthMonitor
  class UrlNotValid < StandardError
    def initialize
      super
    end
  end

  class UrlNotFound < StandardError
    def initialize
      super
    end
  end
end

class App
  def initialize(url, refresh_interval)
    @url = url
    @refresh_interval = refresh_interval
  end

  def start
    req = Net::HTTP.new(@url.host, @url.port)
    req.use_ssl = true if @url.secure?
    req.open_timeout = 5

    loop do
      res = req.get @url.path
      puts "#{@url} -> #{res.code} #{res.message}"
      sleep @refresh_interval
    rescue Errno::ECONNREFUSED
      puts "#{@url} -> Connection refused"
      sleep @refresh_interval
    end

  rescue Interrupt
    puts
  end
end

class Url
  attr_reader :host, :port, :path

  def initialize(host, port, path, secure=false)
    @host = host
    @port = port
    @path = path
    @secure = secure
  end

  def secure?
    @secure
  end

  def to_s
    scheme = secure? ? "https" : "http"
    "#{scheme}://#{host}:#{port}#{path}"
  end
end

class Config
  attr_reader :url, :refresh_interval

  def initialize(argv)
    @argv = argv

    @url = parse_url
    @refresh_interval = parse_refresh_interval
  end

  private
  def parse_url
    raise HealthMonitor::UrlNotFound.new unless @argv[0]
    uri = URI(@argv[0])
    raise HealthMonitor::UrlNotValid.new unless uri.kind_of?(URI::HTTP)
    path = uri.path.empty? ? '/' : uri.path
    secure = uri.scheme == 'https'
    Url.new(uri.host, uri.port, path, secure)
  end

  def parse_refresh_interval
    arg_index = @argv.find_index { |arg| arg.start_with?('--refresh_interval=') }
    return 2 unless arg_index
    arg_value = @argv[arg_index].split('=')[1]
    return 2 unless arg_value
    @argv.delete_at(arg_index)
    arg_value.to_i
  end
end

if ARGV[0] == '--help'
  puts "ruby #{$0} [url] --refresh_interval=[refresh_interval]"
else
  config = Config.new(ARGV)
  App.new(config.url, config.refresh_interval).start
end
