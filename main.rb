#require_relative 'htmlScraper.rb'
require_relative 'waterTemps.rb'
require_relative 'tides.rb'

require 'date'

#time = Time.new
#today = time.strftime("%y%m%d")




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
tideParser.tideMovementsForDay("210209")[1].each do |entry|
  puts "Time: #{entry[0].insert(2, ':')}  Movement: #{entry[1]}"
end
#tideParser.prettifyPrintAll





# 8 days of entries starting on current date
# get current date
# tideParser:  strength of tide (to next)
#
