# encoding: utf-8

$driver = nil

# @private
# Invoke top level methods on last created Appium driver.
def self.method_missing method, *args, &block
  raise "driver is nil. called #{method}" if $driver == nil

  $driver.respond_to?(method) ?
      $driver.send( method, *args, &block ) :
      super
end

module Appium
  # @private
  def self.add_to_path file, path=false
   path = path ? "../#{path}/" : '..'
   path = File.expand_path path, file

   $:.unshift path unless $:.include? path
  end

  add_to_path __FILE__

  require 'appium_lib/driver'
end