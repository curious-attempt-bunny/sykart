class HoursController < ApplicationController
  def index
    races_response = `curl -H "Accept: application/json" -H "X-Query-Key: #{ENV['INSIGHTS_QUERY_KEY']}" "https://insights-api.newrelic.com/v1/accounts/929577/query?nrql=SELECT%20uniqueCount(racer_id),%20average(timestamp)%20from%20RaceDataTest3%20facet%20race_id%20since%201%20weeks%20ago%20limit%201000"`
    @races = JSON.parse(races_response)

    @day = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 } }

    @races["facets"].each do |race|
      racers = race["results"][0]["uniqueCount"]
      start_time = Time.at(race["results"][1]["average"]/1000).
        in_time_zone('Pacific Time (US & Canada)') + 7.hours
      @day[start_time.wday][start_time.hour] += racers
      puts "#{start_time.wday} #{start_time.hour} -> #{racers} #{@day[start_time.wday][start_time.hour]}"
    end
  end
end
