#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'time'
require 'set'

class Hash
  def except(*keys)
    dup.except!(*keys)
  end

  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end

existing_races_response = `curl -H "Accept: application/json" -H "X-Query-Key: #{ENV['INSIGHTS_QUERY_KEY']}" "https://insights-api.newrelic.com/v1/accounts/929577/query?nrql=SELECT%20uniques(race_id)%20from%20RaceDataTest3%20since%201%20day%20ago%20limit%20100"`
existing_races = Set.new(JSON.parse(existing_races_response)['results'].first['members'].map { |f| f.to_i })

races_list_url = URI('http://sirtigard.clubspeedtiming.com/api/index.php/races/since.json?&date=2015-03-17&limit=200&key=cs-dev')
races_list_response = Net::HTTP.get(races_list_url)

races = JSON.parse(races_list_response)['races']

races.each do |race|
  race_id = race['race_id'].to_i
  puts race_id
  next if existing_races.include?(race_id)

  race_url = URI("http://sirtigard.clubspeedtiming.com/api/index.php/races/#{race_id}.json?key=cs-dev")
  race_response = Net::HTTP.get(race_url)
  # puts race_response
  race = JSON.parse(race_response)['race']

  events = []
  race['racers'].each do |racer|
    next unless racer['laps'] && racer['laps'].size > 1
    racer['laps'][1..-1].each do |lap|
      event = race.except('id', 'racers', 'laps', 'track', 'starts_at')
      event['timestamp'] = DateTime.parse(race['starts_at']).to_time.to_f
      event['race_id'] = race['id']
      # event['racer_id'] = racer['id']
      event['lap_id'] = lap['id']
      event.merge!(racer.except('id', 'laps'))
      event.merge!(lap.except('id', 'laps'))

      ["track_id", "heat_type_id", "heat_status_id", "speed_level_id", "speed_level", "duration", "race_number", "race_id", "lap_id", "rpm_change", "start_position", "kart_number", "rpm", "is_first_time", "finish_position", "total_customers", "ranking_by_rpm", "group_id", "total_visits", "total_races", "lap_number", "racer_id"].each do |integer_attribute|
        event[integer_attribute] = event[integer_attribute].to_i
      end
      ["lap_time"].each do |floating_attribute|
        event[floating_attribute] = event[floating_attribute].to_f
      end
      event['eventType'] = "RaceDataTest3"
      events << event
    end
  end

  File.write('events.json', events.to_json)
  # http = Net::HTTP.new("insights-collector.newrelic.com")

  # request = Net::HTTP::Post.new("/v1/accounts/929577/events")
  # request.body = events.to_json
  # request.content_type = 'application/json'
  # request['X-Insert-Key'] = "vilnELXX4PmXphaaCFBaYBeondIUY66K"
  # response = http.request(request)

  # puts response.inspect
  output = `cat events.json | curl -d @- -X POST -H "Content-Type: application/json" -H "X-Insert-Key: #{ENV['INSIGHTS_INSERT_KEY']}" https://insights-collector.newrelic.com/v1/accounts/929577/events`
  puts output
  # exit(0)

end
