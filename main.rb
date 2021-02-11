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
    @tideWidgetAndData.analyseAllTides
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
    end #each

    @allData.each do |entry|
      entry["dailyForecast"] = @openWeatherWidgetAndData.getForecastFromDaily(entry["yymmdd"])
      entry["sunTimes"] = @openWeatherWidgetAndData.findSunTimes(entry["yymmdd"])
      entry["dayAllTides"] = @tideWidgetAndData.tideMovementsForDay(entry["yymmdd"])
    end #each
  end #populateDataFields


  def whatFishAreAround
    # this might take a while
  end


  def tideWindCheck(day)
    potentialTidesNoWind = []

    day["dayAllTides"][1].each do |tideEntry|
      rating = @tideWidgetAndData.tideRater(tideEntry[1])
      if rating > 0
        potentialTidesNoWind.push([rating, tideEntry[0], tideEntry[1]])
      end # if rating
    end # each

    goodTidesAndWeather = []

    potentialTidesNoWind.each do |potentialTide|
      hh = potentialTide[1].slice(0...2)
      yymmddhh = "#{day["yymmdd"]}#{hh}"
      weatherAtThatTime = @openWeatherWidgetAndData.getForecastFromYYMMDDHH(yymmddhh)
      windSpeed = 9999

      if weatherAtThatTime["forecastSource"] == "hourly"
        windSpeed = weatherAtThatTime["windAvg"]
      else #daily data
        windSpeed = weatherAtThatTime["wind"]
      end #if

      if Integer(hh, 10) > 19 #night fishing
        if windSpeed < 16
          goodTidesAndWeather.push([potentialTide, weatherAtThatTime])
        end #if
      else #day fishing
        if windSpeed < 20
          goodTidesAndWeather.push([potentialTide, weatherAtThatTime])
        end #if
      end #if
    end #each
      return goodTidesAndWeather # [[rating, time, movement], [{weather}]]
  end


  def reportDayEntry(day)

    date = Integer(day["yymmdd"].slice(4...6), 10)
    entry = "#{''.ljust(79, '-')}\n#{day["day"]} #{date}\n"
    chronologicalEntry = []
    goodTidesAndWeather = tideWindCheck(day)

    if goodTidesAndWeather.length < 1
      entry += "\n\nGo do something else fun today. The day brings nothing but trouble.\n\n\n\n#{''.ljust(80, '-')}"
      puts entry
      return
    end

    entry += "Water temperature is #{day["waterTemp"]} C\n\n\nGood times to be out:\n\n"
    #DAILYFORECAST SUMMARY
    #FISHDB THING HERE

    tideReport = ""

    goodTidesAndWeather.each do |tideEntry|

      hhmm = tideEntry[0][1]
      rating = tideEntry[0][0]
      movement = tideEntry[0][2]
      descriptor = ""
      individualTideDescr = "  #{hhmm.insert(2, ':')} movement of #{movement}\n"
      if rating == 1
        descriptor = "        A bit of a trickle.\n"
      elsif rating == 2
        descriptor = "        A reasonable flow.\n"
      elsif rating == 3
        descriptor = "        A pretty good flow.\n"
      elsif rating == 4
        descriptor = "        A strong flow.  Your light stuff probably won't make it to the seabed.\n"
      elsif rating == 5
        descriptor = "        A HUGE flow!  Get your heavy lures out!  A top 5% flow for the year!\n"
      elsif rating == 6
        descriptor = "        END TIMES TORRENTIAL!  The top 1% flow for this whole year!!  It's gonna be like a river!!\n"
      end

      individualTideDescr += descriptor


      tideWeatherReport = "\n"
      if tideEntry[1]["forecastSource"] == "hourly"
        general = tideEntry[1]["weatherDescrFirstLast"][0]
        if tideEntry[1]["weatherDescrFirstLast"][0] != tideEntry[1]["weatherDescrFirstLast"][1]
          general = "#{tideEntry[1]["weatherDescrFirstLast"][0]} to #{tideEntry[1]["weatherDescrFirstLast"][1].downcase}".capitalize
        end
        windSpeed = tideEntry[1]["windAvg"]
        windDir = "the #{tideEntry[1]["windDirFirstLast"][0]}"
        if tideEntry[1]["windDirFirstLast"][0] != tideEntry[1]["windDirFirstLast"][1]
          windDir = "the #{tideEntry[1]["windDirFirstLast"][0]}, shifting to a #{tideEntry[1]["windDirFirstLast"][1]} wind"
        end

        windDescription = "and a relatively still and windless day"
        if windSpeed > 10
          windDescription = "#{windSpeed}kph winds from #{windDir}"
        elsif windSpeed > 6
          windDescription = "with a cool #{windSpeed}kph breeze"
        elsif windSpeed > 2
          windDescription = "with a calm breeze"
        end




        humidity = ""
        if tideEntry[1]["humidityAvg"] >= 90
          humidity = "        Humid"
        elsif tideEntry[1]["humidityAvg"] >= 80
          humidity = "        A bit humid"
        elsif tideEntry[1]["humidityAvg"] >= 60
          humidity = "        Comfortably dry"
        else
          humidity = "        Don't forget that lip balm!  Pretty dry"
        end

        rainChance = ""
        if tideEntry[1]["precipChanceAvg"] > 0.3
          rainChance = " with a #{tideEntry[1]["precipChanceAvg"] * 10}% chance of rain"
        end

        tideWeatherReport = "        #{general} #{windDescription}.\n#{humidity}#{rainChance}.\n\n"
      end # if hourly

      individualTideDescr += tideWeatherReport
      tideReport += individualTideDescr
      # day weather
    end #for each good entry
    entry += tideReport
    puts entry
  end # report day entry


  def testReport
    @allData.each do |day|
      reportDayEntry(day)
    end
  end

end # WhenShouldIGoFishing

whenShouldIGoFishing = WhenShouldIGoFishing.new
whenShouldIGoFishing.populateDataFields
whenShouldIGoFishing.testReport

gets


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
