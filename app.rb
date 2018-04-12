#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require

API = Panoptes::Client.new(auth: {token: `panoptes-token`.strip})
HASHTAG = "#zoonibotted"

class Responder
  attr_reader :matches

  def initialize(matches)
    @matches = matches
  end

  def response_for(body)

    key, response = matches.find do |key, response|
      body.include?(key)
    end

    response
  end
end

class Discussion
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def already_responded?
    response = API.talk.get("/comments", discussion_id: id)
    comments = response.fetch("comments")
    tags = comments.map { |comment| comment.fetch("tagging") }.flatten

    puts tags.inspect
                
    tags.any? { |tag| tag == HASHTAG }
  end

  def post(response)
    body = "I am Zoonibot, a humble computer program. The people who 'helpfully' programmed me have asked me to say:\n"
    body += response
    body += "\n #{HASHTAG}"

    API.create_comment discussion_id: id, body: body
  end
end

class Event
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def data
    event["data"]
  end

  def handle
    return false unless event["source"] == "talk"
    return false unless event["type"] == "comment"

    responder = PROJECTS[data["project_id"]]
    return false unless responder

    response = responder.response_for(data["body"])
    return false unless response

    puts "Matched: #{data.inspect}"
    
    discussion = Discussion.new(data["discussion_id"])
    return false if discussion.already_responded?

    discussion.post(response)

    puts data.inspect
    puts response
  end
end

PROJECTS = {
  643 => Responder.new(
    "hello" => "Hi, I'm a robot!",
    "go away" => "Fine. Be that way.",
    "#needs_cleanup" => "You have suggested that this subject may be in need of editorial review. Thank you for letting us know."
  ),

  4973 => Responder.new(
    "#needs_cleanup" => "You have suggested that this subject may be in need of editorial review. Thank you for letting us know."
  )

#  5733 => Responder.new( # galaxy zoo
#
#  )
}

# "I am Zoonibot. The people who 'helpfully' programmed me have asked me to say
# at this juncture that a Gamma Doradus variable is a type of star that
# undergoes periodic variations in brightness. There's more info here,
# http://en.wikipedia.org/wiki/Gamma_Doradus_variable , for what it's worth.
# #zoonibotans"


