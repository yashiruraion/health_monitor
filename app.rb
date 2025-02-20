require 'net/http'

module HealthMonitor
  module Exceptions
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

  module Print
    def self.normal(text='')
      puts text
    end

    def self.green(text='')
      puts "\e[38;2;0;255;0m#{text}\e[0m"
    end

    def self.red(text='')
      puts "\e[38;2;255;0;0m#{text}\e[0m"
    end

    def self.yellow(text='')
      puts "\e[38;2;255;255;0m#{text}\e[0m"
    end
  end

  class App
    def initialize(config)
      @config = config
    end

    def start
      req = Net::HTTP.new(@config.url.host, @config.url.port)
      req.use_ssl = true if @config.url.secure?
      req.open_timeout = 5

      loop do
        res = req.get @config.url.path
        text = "#{@config.url} -> #{res.code} #{res.message}"
        case res.code.to_i
        when 100..199
          Print.yellow(text)
        when 200..299
          Print.green(text)
        when 300..399
          Print.yellow(text)
        else
          Print.red(text)
        end
        sleep @config.refresh_interval
      rescue Errno::ECONNREFUSED
        Print.red "#{@config.url} -> Connection refused"
        sleep @config.refresh_interval
      end

    rescue Interrupt
      Print.normal
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
      raise Exceptions::UrlNotFound.new unless @argv[0]
      uri = URI(@argv[0])
      raise Exceptions::UrlNotValid.new unless uri.kind_of?(URI::HTTP)
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
end

if ARGV[0] == '--help'
  HealthMonitor::Print.normal "ruby #{$0} [url] --refresh_interval=[refresh_interval]"
else
  HealthMonitor::App.new(HealthMonitor::Config.new(ARGV)).start
end
