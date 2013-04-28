#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'date'
require 'rake'
require 'json'
require_relative 'ward_list_importer'

# load the rails environment
require File.dirname(__FILE__) + "/../../config/environment"

UPDATEDIR = "#{Rails.root}/db/updateScripts/"

begin
  log_file = "#{UPDATEDIR}WardListImport.log"
  puts "Logging to #{log_file}"
  $stdout = File.open(log_file,'a')
  puts Time.now.strftime("%a %b %d %Y - %I:%M %p")

  updater = WardListImporter.new RootAdmin.first
  updater.run

  puts "Finished update at #{Time.now}"
rescue Exception => ex
  puts "We had a failure. Printing error: "
  # Printing stack trace first because we had a problem where the lds.org signin page had unicode characters that caused 
  # the message on the exception not to print
  puts ex.backtrace.join("\n")
  p ex
end
