class RacersController < ApplicationController
  def show
    races_response = `curl -H "Accept: application/json" -H "X-Query-Key: #{ENV['INSIGHTS_QUERY_KEY']}" "https://insights-api.newrelic.com/v1/accounts/929577/query?nrql=SELECT%20min(lap_time)%20from%20RaceDataTest3%20where%20kart_number%20%3E%200%20and%20kart_number%20%3C%2020%20and%20lap_time%20%3E%200%20and%20racer_id%20%3D%20#{params[:id].to_i}%20facet%20race_id%20since%2012%20months%20ago%20limit%201000"`
    races = JSON.parse(races_response)

    @times = races["facets"].map { |race| race["results"][0]["min"] }
    @times.sort!
  end
end
