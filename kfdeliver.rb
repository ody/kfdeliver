#!/usr/bin/env ruby

require 'rubygems'
require 'net/http'
require 'nokogiri'

# Posts your login information to kindlefeeder and returns a session Cookie so
# our subsequent posts authenticate.
def login(user, password)

  url = URI.parse('http://www.kindlefeeder.com/sessions')
  connection = Net::HTTP.new(url.host, url.port).start
  token = token('http://www.kindlefeeder.com/sessions/new', connection)
  request = Net::HTTP::Post.new(url.path, { 'Referer' => 'http://www.kindlefeeder.com/sessions/new', 'Cookie' => token[1] })
  data = { 'login' => user, 'password' => password, 'commit' => 'Log in', 'authenticity_token' => token[0] }
  request.set_form_data(data)
  response = connection.request(request)
  return response['Set-Cookie'].scan(/_kf3_session=.*/)[0].split('; ')[0], token[0]

end

def token(target, connection)

  url = URI.parse(target)
  request = Net::HTTP::Get.new(url.path)
  get = connection.request(request)
  noko = Nokogiri::HTML(get.body)
  return noko.xpath('//input[@name="authenticity_token"]').first['value'], get['Set-Cookie'].scan(/_kf3_session=.*/)[0].split('; ')[0]

end

def deliver(user, password, uid)

  authed = login(user, password)
  url = URI.parse("http://www.kindlefeeder.com/users/#{uid}/deliveries")
  connection = Net::HTTP.new(url.host, url.port).start
  request = Net::HTTP::Post.new(url.path, { 'Cookie' => authed[0] })
  request.set_form_data({ "delivery[delivery_type]" => "emailed", "authenticity_token" => authed[1] })
  connection.request(request)

end

deliver(ARGV[0], ARGV[1], ARGV[2])
