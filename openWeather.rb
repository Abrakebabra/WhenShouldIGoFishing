#"id": 1851100,
#        "name": "Takamatsu",
#        "state": "",
#        "country": "JP",
#        "coord": {
#            "lon": 134.043335,
#            "lat": 34.340279

=begin
"current"
"hourly"
"daily"
=end



require 'HTTParty'
require 'date'
require 'json'


class OpenWeatherMap

  @@time = Time.new

  def initialize
    @authorization = ''
    @oneCallAddress = 'https://api.openweathermap.org/data/2.5/onecall?lat=34.340279&lon=134.043335&units=metric&appid='
    @calledJSON = {}
  end


  def authorize
    file = File.open('Private/OpenWeatherMap API Key.txt')
    @authorization = file.read
    file.close
  end


  def oneCall
    addressAndKey = "#{@oneCallAddress}#{@authorization}"
    response = HTTParty.get(addressAndKey)
    responseBody = response.body
    @calledJSON = JSON.parse(responseBody)
  end


  def testCall
    f = File.open("TestsAndLearning/omwTest.txt")
    fData = f.read
    f.close
    @calledJSON = JSON.parse(fData)
  end


  def convertJST(unixDateTime)
    jst = Time.at(Integer(unixDateTime))
    jstFormatted = jst.strftime("%y%m%d%H")
    return String(jstFormatted)
  end


  def getForecastFromTime


    #hourly first
    @calledJSON["hourly"].each do |hourly|
      jst = convertJST(hourly["dt"])
      date = jst.slice(0..5)
      time = jst.slice(6..8)
      #if date == workingDate

      #else
      #  dateEntry.push(Integer(date))
      #  workingDate = date
      #end

      puts "#{date} @ #{time}: #{Integer(hourly["temp"])}C #{hourly["weather"][0]["description"]} with windspeed of #{Integer(hourly["wind_speed"] * 3.6)} kph"
    end
  end




  def printCalledJSON
    puts @calledJSON
  end


end

owm = OpenWeatherMap.new
#owm.authorize
#owm.oneCall
owm.testCall
owm.getForecastFromTime
#owm.printCalledJSON
