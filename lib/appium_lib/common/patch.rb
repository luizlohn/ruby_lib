# encoding: utf-8
module Appium::Common
  # Implement useful features for element.
  class Selenium::WebDriver::Element
    # Note: For testing .text should be used over value, and name.

    # Returns the value attribute
    #
    # Fixes NoMethodError: undefined method `value' for Selenium::WebDriver::Element
    def value
      self.attribute :value
    end

    # Returns the name attribute
    #
    # Fixes NoMethodError: undefined method `name' for Selenium::WebDriver::Element
    def name
      self.attribute :name
    end

    # Returns the type attribute
    #
    # Fixes Selenium::WebDriver::Error::UnknownError: Not yet implemented
    def tag_name
      self.attribute :type
    end

    # For use with mobile tap.
    #
    # ```ruby
    # execute_script 'mobile: tap', :x => 0.0, :y => 0.98
    # ```
    #
    # https://github.com/appium/appium/wiki/Automating-mobile-gestures
    # @return [OpenStruct] the relative x, y in a struct. ex: { x: 0.50, y: 0.20 }
    def location_rel
      xy = self.location
      w = window_size
      OpenStruct.new( x: xy.x.to_f / w.width.to_f,
                      y: xy.y.to_f / w.height.to_f )
    end
  end
end # module Appium::Common

# Print JSON posted to Appium. Not scoped to an Appium module.
#
# Requires from lib/selenium/webdriver/remote.rb
require 'selenium/webdriver/remote/capabilities'
require 'selenium/webdriver/remote/bridge'
require 'selenium/webdriver/remote/server_error'
require 'selenium/webdriver/remote/response'
require 'selenium/webdriver/remote/commands'
require 'selenium/webdriver/remote/http/common'
require 'selenium/webdriver/remote/http/default'

# @private
# Show http calls to the Selenium server.
#
# Invaluable for debugging.
def patch_webdriver_bridge
  Selenium::WebDriver::Remote::Bridge.class_eval do
    # Code from lib/selenium/webdriver/remote/bridge.rb
    def raw_execute(command, opts = {}, command_hash = nil)
      verb, path = Selenium::WebDriver::Remote::COMMANDS[command] || raise(ArgumentError, "unknown command: #{command.inspect}")
      path       = path.dup

      path[':session_id'] = @session_id if path.include?(':session_id')

      begin
        opts.each { |key, value| path[key.inspect] = escaper.escape(value.to_s) }
        rescue IndexError
        raise ArgumentError, "#{opts.inspect} invalid for #{command.inspect}"
      end

      # convert /// into /
      path.gsub! /\/+/, '/'

      # change path from session/efac972c-941a-499c-803c-d7d008749/execute
      # to /execute
      # path may be nil, session, or not have anything after the session_id.
      path_str = ''
      path_match = path.match /.*\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/
      path_str = path.sub(path_match[0], '') unless path_match.nil?

      puts "#{verb} #{path_str}"
      unless command_hash.nil? || command_hash.length == 0
        print_command = command_hash.clone
        print_command.delete :args if print_command[:args] == []
        ap print_command
      end
      # puts "verb: #{verb}, path #{path}, command_hash #{command_hash.to_json}"
      http.call verb, path, command_hash
    end # def
  end # class
end # def

# Print Appium's origValue error messages.
class Selenium::WebDriver::Remote::Response
  # @private
  def error_message
    val = value

    case val
      when Hash
        msg = val['origValue'] || val['message'] or return 'unknown error'
        msg << " (#{ val['class'] })" if val['class']
      when String
        msg = val
      else
        msg = "unknown error, status=#{status}: #{val.inspect}"
    end

    msg
  end
end