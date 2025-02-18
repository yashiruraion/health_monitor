require 'net/http'

class Url
  def initialize(address)
    @uri = URI(address)
    raise NotValidUrl.new(address) unless @uri.kind_of?(URI::HTTP)
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

class NotValidUrl < StandardError
  def initialize(address)
    super("Url '#{address}' is not valid")
  end
end

class MissingUrl < StandardError
  def initialize
    super('Url is missing')
  end
end

class App
  def initialize(url, refresh_interval)
    @url = url
    @refresh_interval = refresh_interval
  end

  def start
    req = Net::HTTP.new(@url.host, @url.port)
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

class Arg
  attr_reader :refresh_interval

  def initialize(argv)
    @argv = argv
    @refresh_interval = parse_refresh_interval
  end

  def url
    raise MissingUrl.new unless @argv[0]
    Url.new(@argv[0])
  end

  private
  def parse_refresh_interval
    arg_index = @argv.find_index { |arg| arg.start_with?('--refresh_interval=') }
    return 2 unless arg_index
    arg_value = @argv[arg_index].split('=')[1]
    return 2 unless arg_value
    @argv.delete_at(arg_index)
    arg_value.to_i
  end
end

begin
  arg = Arg.new(ARGV)
  App.new(arg.url, arg.refresh_interval).start
rescue => ex
  puts "ERROR : #{ex.message}"
  puts "ruby #{$0} [url] --refresh_interval=[refresh_interval]"
end
