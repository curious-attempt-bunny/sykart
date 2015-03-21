class RacesController < ApplicationController
  def show
    race_id = params[:id].to_i

    races_list_url = URI("http://sirtigard.clubspeedtiming.com/api/index.php/races/since.json?&date=#{(DateTime.now - 3).to_s[0..9]}&limit=200&key=cs-dev")
    races_list_response = Net::HTTP.get(races_list_url)
    @races = JSON.parse(races_list_response)['races']
    @races.each do |race|
      race['race_id'] = race['race_id'].to_i
      race['finish_time'] = DateTime.parse(race['finish_time'])
    end
    @races.sort_by! { |race| race['finish_time'] }.reverse!

    if params[:id] == 'latest'
      race_id = @races.max_by { |race| race["finish_time"] }['race_id']
    end

    race_url = URI("http://sirtigard.clubspeedtiming.com/api/index.php/races/#{race_id}.json?key=cs-dev")
    race_response = Net::HTTP.get(race_url)

    @race = JSON.parse(race_response)['race']

    @race["racers"].sort_by! do |racer|
      racer["laps"].reject { |lap| lap["lap_time"].to_f.zero? }.
          map { |lap| lap["lap_time"].to_f }.
          min
    end

    @racers_by_hp = {}
    @racers_by_hp[6.5] = @race["racers"].select { |racer| racer["kart_number"].to_i < 20 }
    @racers_by_hp[9] = @race["racers"].select { |racer| racer["kart_number"].to_i >= 20 }

    @racers = @race["racers"]
  end
end
