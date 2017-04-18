#!/usr/bin/ruby

require 'faraday'
require 'uri'
require 'digest'
require 'optparse'
require 'json'

class ClientError
end

class Client
  def initialize(endpoint, user_id, api_secret)
    @user_id = user_id
    @api_secret = api_secret
    @conn = Faraday.new(endpoint)
  end

  # order one or more waffles
  def order(waffle_name, coords, count=1)
    params = {waffle: waffle_name, count: count, lat: coords[0], long: coords[1]}
    return api_call('/orders', params)
  end

  # Make an API call with parameters to the specified path
  def api_call(path, params, debug_responses=false)
    body = make_post(params)
    resp = @conn.post(path, body)

    return resp if debug_responses

    # try to decode response as json
    if resp.headers['content-type'] == 'application/json'
      begin
        data = JSON.parse(resp.body)
      rescue JSON::ParserError
        puts "Failed to parse #{resp.body}"
      end
    end

    if resp.status != 200
      raise "Non 200 error code: #{resp.status} -- #{resp.body}"
    end

    return data || resp.body
  end

  private

  def make_post(params)
    params[:user_id] = @user_id
    body = URI.encode_www_form(params)

    sig = signature(body)
    body += '|sig:' + sig

    return body
  end

  def signature(message)
     Digest::SHA1.hexdigest(@api_secret + message)
  end
end

if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.banner = "usage: client.rb [options]"

    opts.on('-e endpoint', "Endpoint to issue requests against") do |endpoint|
      options[:endpoint] = endpoint
    end

    opts.on('-u user_id', "User ID for requests") do |user_id|
      options[:user_id] = user_id
    end

    opts.on('-s secret', "User's secret key") do |secret|
      options[:secret] = secret
    end

    opts.on('-w waffle', "waffle requested") do |waffle|
      options[:waffle] = waffle
    end

    opts.on("-c", "--coords lat,long", Array, "Where the waffle should be delivered") do |coords|
      options[:coords] = coords
    end
  end.parse!

  c = Client.new(options[:endpoint], options[:user_id], options[:secret])
  puts c.order(options[:waffle], options[:coords])
end