require_relative 'waterTemps.rb'
require_relative 'tides.rb'
require_relative 'openWeather.rb'

require 'date'

=begin
How to handle the data?
Check - will there always be 8 days of entries?

Make 8 days of entries and populate in data format
[{YYMMDD, DayOfWeek, waterTemp forecast, daily forecast, sunrise/sunset, tidedata - with hourly forecast if available, tidesWorthShowing - or keep it in a function}]
-owm get daily forecast first
-add water temp
-add all tide data
-add hourly forecast to tide data if possible

From there, can filter and play with everything
 - filter out small tides
 - filter out windy times/days

If no good tides show up, don't have anything for the day, or a nice message
If a tide pops up, compare forecast temp to fishdb -

Maybe
-----------
Monday 8 February
"stay home it's not worth it"

----------
Tuesday 9 February
Water temp is 8.6C
Go catch some .....
Maybe a chance of .....

Tides
(02:48am tide - exclude from report)

sunrise at .....

10:17 with a medium flow of 224cm!
== weather data at this time ==

sunset at .....

21:06 with a large flow of -154cm!
== no hourly data for this.  Check the general weather for the day below ==


== general daily weather ==
=end

class WhenShouldIGoFishing
  @@time = Time.new
  def initialize
    @today = @@time.strftime("%y%m%d")

    @tideWidgetAndData = TideDataParser.new
    @waterTempWidget = WaterTemperature.new
    @openWeatherWidgetAndData = OpenWeatherMap.new

    @tideWidgetAndData.getData
    @waterTempWidget.scrapeData
    #@waterTempWidget.getTestData
    @openWeatherWidgetAndData.authorize
    @openWeatherWidgetAndData.oneCall
    #@openWeatherWidgetAndData.testCall

    @waterTempData = @waterTempWidget.output
    @openWeatherWidgetAndData.getSun
    @allData = Array.new(8) {
      {
        "yymmdd" => "999999",
        "day" => "____day",
        "waterTemp" => 99.99,
        "dailyForecast" => {
          "forecastSource" => "NULL",
          "wind" => 999,
          "windDir" => "NULL",
          "precipitation" => 999.9,
          "humidity" => 999,
          "weatherDescription" => "NULL"},
        "sunTimes" => [
          "sunrise hhmm",
          "sunset hhmm"],
        "dayAllTides" => [
          "yymmdd", [
            ["time", "diff"]
            ]],
      } #hash table structure
    } #array element content

  end #@allData variable


  def populateDataFields
    @waterTempData.each.with_index do |wtEntry, index|

      @allData[index]["yymmdd"] = wtEntry["yymmdd"]
      @allData[index]["day"] = wtEntry["dayEn"]
      @allData[index]["waterTemp"] = wtEntry["temp"]
    end

    @allData.each do |entry|
      entry["dailyForecast"] = @openWeatherWidgetAndData.getForecastFromDaily(entry["yymmdd"])
      entry["sunTimes"] = @openWeatherWidgetAndData.findSunTimes(entry["yymmdd"])
      entry["dayAllTides"] = @tideWidgetAndData.tideMovementsForDay(entry["yymmdd"])
      puts entry
    end
  end


  def whatFishAreAround
    # this might take a while
  end


  def reportDayEntry(yymmdd)
    entry = ""





  end

end # WhenShouldIGoFishing

whenShouldIGoFishing = WhenShouldIGoFishing.new
whenShouldIGoFishing.populateDataFields



#Tide from https://www.data.jma.go.jp/gmd/kaiyou/db/tide/suisan/suisan.php
#tideParser = TideDataParser.new
#tideParser.getData
#dateTest = tideParser.tideMovementsForDay(today)
#tideParser.analyseAllTides
#dateTest[1].each do |entry|
#  rating = tideParser.tideRater(entry[1])
#  if rating == 1
#    puts "Time: #{entry[0].insert(2, ':')}  Enough water is moving: #{entry[1]}"
#  elsif rating == 2
#    puts "Time: #{entry[0].insert(2, ':')}  Medium flow: #{entry[1]}"
#  elsif rating == 3
#    puts "Time: #{entry[0].insert(2, ':')}  Large flow: #{entry[1]}"
#  elsif rating == 4
#    puts "Time: #{entry[0].insert(2, ':')}  Unusually large flow: #{entry[1]}"
#  elsif rating == 5
#    puts "Time: #{entry[0].insert(2, ':')}  Huge flow: #{entry[1]}"
#  elsif rating == 6
#    puts "Time: #{entry[0].insert(2, ':')}  END TIMES TORRENTIAL FLOW: #{entry[1]}"
#  end
#end
#tideParser.allTideMovements
#tideParser.prettifyPrintAll





# 8 days of entries starting on current date
# get current date
# tideParser:  strength of tide (to next)
# If tide starts moving within 2 hours of sunset, highlight that time
