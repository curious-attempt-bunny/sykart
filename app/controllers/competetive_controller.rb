class CompetetiveController < ApplicationController
  def index
    races_response = `curl -H "Accept: application/json" -H "X-Query-Key: #{ENV['INSIGHTS_QUERY_KEY']}" "https://insights-api.newrelic.com/v1/accounts/929577/query?nrql=SELECT%20average(timestamp),%20min(lap_time)%20from%20RaceDataTest3%20where%20kart_number%20<%2020%20and%20lap_time%20>%200%20facet%20race_id%20since%201%20weeks%20ago%20limit%201000"`
    @races = JSON.parse(races_response)

    @min = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 1000 } }

    @races["facets"].each do |race|
      start_time = Time.at(race["results"][0]["average"]/1000).
        in_time_zone('Pacific Time (US & Canada)') + 7.hours
      lap_time = race["results"][1]["min"].to_f
      @min[start_time.wday][start_time.hour] = [@min[start_time.wday][start_time.hour], lap_time].min
    end

    times = @min.values.map(&:values).flatten.sort!
    @scales = (0...16).map { |i| times[((times.size*i) / 16).to_i]}
  end
end
