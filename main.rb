require_relative 'waterTemps.rb'
require_relative 'tides.rb'
require_relative 'openWeather.rb'
require 'date'

=begin
How to handle the data?
Check - will there always be 8 days of entries?

Make 8 days of entries and populate in data format
[{YYMMDD, DayOfWeek, waterTemp forecast, daily forecast, sunrise/sunset, tidedata - with hourly forecast if available}]
-owm get daily forecast first
-add water temp
-add all tide data to each date
-add hourly forecast to tide data if possible

From there, can filter and play with everything
 - filter out small tides
 - filter out windy times/days

If no good tides show up, don't have anything for the day, or a nice message
If a tide pops up, compare forecast temp to fishdb
-----------
Monday 8 February

=end

class WhenShouldIGoFishing
  @@time = Time.new
  def initialize
    @today = @@time.strftime("%y%m%d")

    @tides = TideDataParser.new
    @waterTemp = WaterTemperature.new
    @openWeather = OpenWeatherMap.new


  end

end



time = Time.new
today = time.strftime("%y%m%d")




# Water Temperature Data
waterTemp = WaterTemperature.new

#waterTemp.scrapeData
waterTemp.testData

waterTemp.pickData
waterTempForecast = waterTemp.output
waterTemp.print

#Tide from https://www.data.jma.go.jp/gmd/kaiyou/db/tide/suisan/suisan.php
tideParser = TideDataParser.new
tideParser.getData
dateTest = tideParser.tideMovementsForDay(today)
tideParser.analyseAllTides
dateTest[1].each do |entry|
  rating = tideParser.tideRater(entry[1])
  if rating == 1
    puts "Time: #{entry[0].insert(2, ':')}  Enough water is moving: #{entry[1]}"
  elsif rating == 2
    puts "Time: #{entry[0].insert(2, ':')}  Medium flow: #{entry[1]}"
  elsif rating == 3
    puts "Time: #{entry[0].insert(2, ':')}  Large flow: #{entry[1]}"
  elsif rating == 4
    puts "Time: #{entry[0].insert(2, ':')}  Unusually large flow: #{entry[1]}"
  elsif rating == 5
    puts "Time: #{entry[0].insert(2, ':')}  Huge flow: #{entry[1]}"
  elsif rating == 6
    puts "Time: #{entry[0].insert(2, ':')}  END TIMES TORRENTIAL FLOW: #{entry[1]}"
  end
end
#tideParser.allTideMovements
#tideParser.prettifyPrintAll


owm = OpenWeatherMap.new
#owm.authorize
#owm.oneCall
owm.testCall
owm.getSun
#owm.getForecastTest
#owm.printCalledJSON
#puts owm.getForecastFromDaily(today)
#puts owm.getForecastFromHourly("21020915")
#puts owm.getForecastFromYYMMDDHH("21021019")



# 8 days of entries starting on current date
# get current date
# tideParser:  strength of tide (to next)
# If tide starts moving within 2 hours of sunset, highlight that time
