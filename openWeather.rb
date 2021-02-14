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


functions

Hourly vs daily
function to enter in target hour
takes the average wind speed of the 6 hours after
takes the average precipitation percentage
takes average humidity

if 6 hours are not available, just take the average of whatever it can get
if the target hour is not on the hourly list, grab the wind forecast from the daily forecast
Optional if have time:  If target date is not on hourly list, go straight to daily without checking hours
 - maybe later.  Get it working first.
Grab the first and last available weather description.  If not the same, have "xx description to yy description"
grab the first and last available wind direction.  Same thing.  More useful than average direction.


Sun
grab sunrise sunset times for each day
=end

# https://jsonformatter.curiousconcept.com/
# Lifesaver


require 'HTTParty'
require 'date'
require 'json'


class OpenWeatherMap

  @@time = Time.new

  def initialize
    @authorization = ''
    @workingDirectory = File.dirname(__FILE__)
    @oneCallAddress = 'https://api.openweathermap.org/data/2.5/onecall?lat=34.340279&lon=134.043335&units=metric&appid='
    @calledJSON = {}
    @sunTimes = []
  end


  def authorize
    directory = @workingDirectory.gsub('WhenShouldIGoFishing', '')
    file = File.open("#{directory}Private/OpenWeatherMap API Key.txt")
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
    jstFormatted = jst.strftime("%y%m%d%H%M")
    return String(jstFormatted)
  end


  # source: http://snowfence.umn.edu/Components/winddirectionanddegrees.htm
  def windDegToCardinal(deg)
    if deg < 11.25
      return "N"
    elsif deg < 33.75
      return "NNE"
    elsif deg < 56.25
      return "NE"
    elsif deg < 78.75
      return "ENE"
    elsif deg < 101.25
      return "E"
    elsif deg < 123.75
      return "ESE"
    elsif deg < 146.25
      return "SE"
    elsif deg < 168.75
      return "SSE"
    elsif deg < 191.25
      return "S"
    elsif deg < 213.75
      return "SSW"
    elsif deg < 236.25
      return "SW"
    elsif deg < 258.75
      return "WSW"
    elsif deg < 281.25
      return "W"
    elsif deg < 303.75
      return "WNW"
    elsif deg < 326.25
      return "NW"
    elsif deg < 348.75
      return "NNW"
    else
      return "N"
    end
  end #windDegToCardinal


  def msToKph(ms)
    return (ms * 3.6).round(1)
  end


  def avgOfArray(array)
    return (array.sum / array.length).round(1)
  end


  # returns nil if not found
  # string input
  def getForecastFromHourly(yymmddhh)
    @calledJSON["hourly"].each.with_index do |hour, index|
      if yymmddhh == convertJST(hour["dt"]).slice(0...8)
        windSpeeds = []
        windDirections = [] #first and last
        precipitation = []
        humidity = []
        weatherDescriptions = [] #first and last

        for i in index...index + 6
          if @calledJSON["hourly"][i].nil?
            break
          end

          windSpeeds.push(msToKph(@calledJSON["hourly"][i]["wind_speed"]))
          windDirections.push(@calledJSON["hourly"][i]["wind_deg"])
          humidity.push(@calledJSON["hourly"][i]["humidity"])
          precipitation.push(@calledJSON["hourly"][i]["pop"])
          weatherDescriptions.push(@calledJSON["hourly"][i]["weather"][0]["description"])
        end

        windAvg = (avgOfArray(windSpeeds)).round(0)
        windDirFirstLast = [
          windDegToCardinal(Integer(windDirections[0])),
          windDegToCardinal(Integer(windDirections[windDirections.length - 1]))]
        precipitationAvg = avgOfArray(precipitation)
        humidityAvg = avgOfArray(humidity)
        weatherDescrFirstLast = [weatherDescriptions[0], weatherDescriptions[weatherDescriptions.length - 1]]

        return {
          "forecastSource" => "hourly",
          "windAvg" => windAvg, "windDirFirstLast" => windDirFirstLast,
          "precipChanceAvg" => precipitationAvg, "humidityAvg" => humidityAvg,
          "weatherDescrFirstLast" => weatherDescrFirstLast
        }
      end # if hour is found
    end #look in each hourly entry
    # if yymmddhh not found
    return nil
  end


  def getForecastFromDaily(yymmdd)
    @calledJSON["daily"].each do |day|
        if yymmdd == convertJST(day["dt"]).slice(0...6)
          return {
            "forecastSource" => "daily",
            "wind" => (msToKph(day["wind_speed"])).round(0),
            "windDir" => windDegToCardinal(Integer(day["wind_deg"])),
            "precipitation" => day["pop"],
            "humidity" => day["humidity"],
            "weatherDescription" => day["weather"][0]["description"]
          }

        end #if date found
    end #for each day
    #day not found
    raise StandardError.new "Target date not found in forecast data"
  end # getDailyForecastFrom


  def getForecastFromYYMMDDHH(yymmddhh)
    forecast = getForecastFromHourly(yymmddhh)
    if forecast.nil?
      forecast = getForecastFromDaily(yymmddhh.slice(0...6))
    end
    if forecast.nil?
      raise StandardError.new "Date not found in forecast"
    end
    return forecast
  end


  def getSun
    @calledJSON["daily"].each do |day|
      yymmdd = convertJST(day["dt"]).slice(0...6)
      sunrise = convertJST(day["sunrise"]).slice(6...10)
      sunset = convertJST(day["sunset"]).slice(6...10)
      @sunTimes.push([yymmdd, sunrise, sunset])
    end
  end


  def findSunTimes(yymmdd)
    if @sunTimes.nil?
      raise StandardError.new "no sun data"
    end
    @sunTimes.each do |day|
      if day[0] == yymmdd
        return day[1], day[2]
      end
    end
    raise StandardError.new "findSunTimes day not found"
  end


  def printCalledJSON
    puts @calledJSON
  end

end # class

#omw = OpenWeatherMap.new
#omw.authorize
#omw.oneCall
#puts omw.getForecastFromYYMMDDHH("21021419")
