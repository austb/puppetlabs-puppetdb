#!/usr/bin/env ruby
require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'net/http'
require 'uri'
require 'json'
require 'time'

# Submits a json object of facts to a puppetdb server
class ReplaceFacts < TaskHelper
  def task(fact_json: nil, puppetdb_server: 'http://localhost', puppetdb_port: 8080, **_kwargs)
    return fact_json
    producer_timestamp = Time.now.utc.iso8601(3)
    certname = fact_json[:fqdn]
    uri = URI.parse("http://#{puppetdb_server}:#{puppetdb_port}/pdb/cmd/v1?certname=#{certname}&version=5&command=replace facts&producer-timestamp=#{producer_timestamp}")

    replace_facts_payload = {
      'certname' => certname,
      'environment' => 'bolt-one-off',
      'producer_timestamp' => producer_timestamp,
      'producer' => 'puppetdb-module',
      'values' => fact_json,
    }

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    request.body = replace_facts_payload.to_json

    # Send the request and return the response
    http.request(request)
  end
end

ReplaceFacts.run if $PROGRAM_NAME == __FILE__
