# -*- coding: utf-8 -*-
require 'chatterbot/dsl'
require 'nest'
require 'restclient'
require 'nokogiri'
require 'pry'

SEARCH_URL="http://www.memoiredeshommes.sga.defense.gouv.fr/fr/arkotheque/client/mdh/base_morts_pour_la_france_premiere_guerre/index.php"

redis = Nest.new $0, Redis.new(:url => ENV["REDISCLOUD_URL"])

names = ["caca", "boudin"]
params = {
  action: 1,
  todo: 'rechercher',
  r_c_nom: names.sample
}

RestClient.post(SEARCH_URL, params) do |response, request, result, &block|
  response.follow_redirection(request, result, &block) if [301, 302, 307].include? response.code

  results = Nokogiri::HTML(response, 'iso8859-1')

  results.css("#contenu_central table tr[valign=\"top\"]").each do |result|

    begin
      lastname, firstname = result.css("td").map do |value|
        value.text.strip.force_encoding("iso8859-1").encode("utf-8")
      end
      next unless redis["sent"].sadd("#{firstname}#{lastname}")

      link = result.css(".visualiser a").first["href"].match(/ArkVisuImage\('(.+)'\)/)[1]

      tweet = "#{firstname} #{lastname}, mort pour la France. #{link} #France #WWI"
      p tweet
    rescue => e
      puts e
      puts e.backtrace
    end
  end
end

