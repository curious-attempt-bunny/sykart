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

    url = "http://sirtigard.clubspeedtiming.com/api/index.php/races/#{race_id}.json?key=cs-dev"
    race_response = Rails.cache.fetch(url, expires_in: 1.hour) do
      race_url = URI(url)
      Net::HTTP.get(race_url)
    end

    @race = JSON.parse(race_response)['race']

    @racers = @race["racers"]

    @racers.reject! { |racer| racer["laps"].nil? }

    @racers.each do |racer|
      racer["laps"].reject! { |lap| lap["lap_time"].to_f.zero? }.
          each { |lap| lap["lap_time"] = lap["lap_time"].to_f }
      racer["average"] = racer["laps"].map { |lap| lap["lap_time"] }.sum / racer["laps"].size
      racer["best"] = racer["laps"].map { |lap| lap["lap_time"] }.min
      racer["hp"] = "9"
      racer["hp"] = "6.5" if racer['kart_number'].to_i < 20
      racer["hp"] = "4" if racer['kart_number'].to_i >= 40
    end

    @racers.sort_by! { |racer| racer["best"] }

    kids_karts = @racers.select { |racer| racer['kart_number'].to_i >= 40}
    normal_karts = @racers.select { |racer| racer['kart_number'].to_i < 20}
    fast_karts = @racers.select { |racer| racer['kart_number'].to_i >= 20 && racer['kart_number'].to_i < 40 }

    @best_averages = [normal_karts, fast_karts, kids_karts].map do |karts|
      karts.map { |racers| racers["average"] }.min
    end

    @best_bests = [normal_karts, fast_karts, kids_karts].map do |karts|
      karts.map { |racers| racers["best"] }.min
    end
  end
end
