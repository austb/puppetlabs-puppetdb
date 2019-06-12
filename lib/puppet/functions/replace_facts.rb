# frozen_string_literal: true

require 'bolt/error'
require 'time'

module AddSubmitCommand
  def submit_command(cmd, cmd_ver, payload, producer_timestamp = nil)
    producer_timestamp ||= Time.now.utc.iso8601(3)
    certname = payload[:certname]

    body = JSON.generate(payload.merge(producer_timestamp: producer_timestamp))
    url = URI.escape "#{uri}/pdb/cmd/v1?command=#{cmd}&version=#{cmd_ver}&certname=#{certname}&producer-timestamp=#{producer_timestamp}"

    @http = HTTPClient.new
    begin
      response = http_client.post(url, body: body, header: headers)
    rescue StandardError => e
      raise Bolt::PuppetDBFailoverError, "Failed to query PuppetDB: #{e}"
    end

    if response.code != 200
      msg = "Failed to query PuppetDB: #{response.body}"
      if response.code == 400
        raise Bolt::PuppetDBError, msg
      else
        raise Bolt::PuppetDBFailoverError, msg
      end
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Bolt::PuppetDBError, "Unable to parse response as JSON: #{response.body}"
    end
  rescue Bolt::PuppetDBFailoverError => e
    @logger.error("Request to puppetdb at #{@current_url} failed with #{e}.")
    reject_url
    submit_command(cmd, cmd_ver, payload, producer_timestamp)
  end
end

# Returns the facts hash for a target.
Puppet::Functions.create_function(:replace_facts) do
  # @param target A target.
  # @return The target's facts.
  # @example Getting facts
  #   facts($target)
  dispatch :replace_facts do
    param 'Target', :target
    return_type 'Any'
  end

  def replace_facts(target)
    facts = call_function('facts', target)

    Bolt::PuppetDB::Client.class_eval { include AddSubmitCommand }

    puppetdb_client = Puppet.lookup(:bolt_pdb_client)
    # Bolt executor not expected when invoked from apply block
    executor = Puppet.lookup(:bolt_executor) { nil }
    executor&.report_function_call(self.class.name)

    # puppetdb_client.submit_command
    puppetdb_client.submit_command("replace facts", 5,
                   certname: target.name,
                   environment: nil,
                   producer: nil,
                   values: facts)

  end
end
