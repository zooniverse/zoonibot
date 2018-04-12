#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require
require_relative './app'

post '/' do
  begin
    body = JSON.parse(request.body.read)
    payload = body.fetch("payload")

    payload.each do |event|
      Event.new(event).handle
    end
    
    return ""
  rescue Exception => e
    puts e.inspect
    puts e.message
    puts e.backtrace
  end
end
