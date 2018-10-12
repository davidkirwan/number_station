require 'thor'
require 'fileutils'

module NumberStation
  class CLI < Thor

    desc "hello NAME", "Say hello to NAME"
    long_desc <<-HELLO_LONG_DESC
      `hello NAME`
    HELLO_LONG_DESC
    option :upcase, :type => :boolean
    def hello (name)
      greeting = "Hello, #{name}"
      greeting.upcase! if options[:upcase] == false
      puts greeting
    end

    desc "create_config (--path PATH)", "copy the sample config to current directory."
    long_desc <<-CREATE_CONFIG_LONG_DESC
      `create_config` will copy the sample config from config/config.json to the current directory. If the
      optional parameter `--path PATH` is passed then this file is copied to the location specified by the 
      PATH parameter.
    CREATE_CONFIG_LONG_DESC
    option :path, :type => :string
    def create_config()
      config_location = File.join(File.dirname(__FILE__), "../../config/conf.json")

      if options[:path]
        path = options[:path]
        #write config to path
        puts "Copying sample config to #{path}"
        FileUtils.cp(config_location, path)
      else
        #write config to local directory the binary was called from
        path = Dir.pwd
        puts "Copying sample config to #{path}"
        FileUtils.cp(config_location, path)
      end
    end

  end
end
