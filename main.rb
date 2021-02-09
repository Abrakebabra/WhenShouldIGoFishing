#require_relative 'htmlScraper.rb'
require_relative 'waterTemps.rb'
require_relative 'tides.rb'

require 'date'

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





# 8 days of entries starting on current date
# get current date
# tideParser:  strength of tide (to next)
# If tide starts moving within 2 hours of sunset, highlight that time
