require 'net/http'

module Scraper
  # code pulled from the pushfour AI project; retrieves the non-header response
  # of an HTTP GET request to the given url
  def self.get(url, retries = 10, backoff = 30)
    tries ||= retries
    uri = URI(url)
    res = Net::HTTP.get(uri)
    # Net::HTTP.get can return a number of non-fatal errors caused by busy
    # server, temporary loss of Internet connection, etc. Catch and retry
    # for a limited time before bailing
  rescue Timeout::Error, EOFError, SocketError,
          Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED,
          Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    puts "Encountered an error: #{e}"
    tries -= 1
    raise e if tries.zero?
    sleep backoff * (retries - tries)
    retry
  else
    res
  end
end
