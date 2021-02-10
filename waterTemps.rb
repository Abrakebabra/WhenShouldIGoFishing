
# Identifying information has been removed to prevent potential abuse of source

require 'open-uri'
require 'net/http'
require 'date'
require 'json'

class WaterTemperature

  def initialize
    @sourceData = ''
    @forecastArrayHash = []
    @parsedDataString = ''

    f = File.open('Private/WaterTempForecast.txt')
    fileData = f.read
    f.close
    fileDataJSON = JSON.parse(fileData)
    @address = fileDataJSON['address']
    @testAddress = fileDataJSON['testAddress']
    @forecastStart = fileDataJSON['forecastStart']
    @forecastEnd = fileDataJSON['forecastEnd']
    @forecastSplitID = fileDataJSON['forecastSplitID']
    time = Time.new
    @year = String(time.strftime("%y"))
    @dayEn = {
      "月" => "Monday",
      "火" => "Tuesday",
      "水" => "Wednesday",
      "木" => "Thursday",
      "金" => "Friday",
      "土" => "Saturday",
      "日" => "Sunday"
    }
  end #init


  def scrapeData
    uri = URI.parse(@address)
    response = Net::HTTP.get_response(uri)
    @sourceData = response.body.encode('UTF-8', 'Shift_JIS')
  end


  def dayEnglish(曜日)
    @dayEn.each do |k, v|
      if k == 曜日
        return v
      end
    end #eachdo
    raise StandardError.new "Character not in hash table"
  end #dayEnglish


  def pickData
    sliceStartIndex = @sourceData.index(@forecastStart)
    sliceEndIndex = @sourceData.index(@forecastEnd)
    forecastSlice = @sourceData.slice(Integer(sliceStartIndex + @forecastStart.length)..sliceEndIndex)

    forecastEntries = forecastSlice.split(@forecastSplitID)

    forecastEntries.each do |entry|
      dateRaw = entry.slice(0...5)
      dateMonthSplit = dateRaw.strip.split('/')
      mm = dateMonthSplit[0].rjust(2, '0')
      dd = dateMonthSplit[1].rjust(2, '0')
      yymmdd = "#{@year}#{mm}#{dd}"
      dayJP = entry.slice(6...7)
      dayEn = dayEnglish(dayJP)
      temp = entry.slice(9...13).delete(' ')
      @forecastArrayHash.push({"dayJP" => dayJP, "dayEn" => dayEn, "yymmdd" => yymmdd, "temp" => temp})
    end #eachdo
  end #parse


  def output
    pickData
    if @forecastArrayHash.empty?
      raise StandardError.new "forecastArrayHash is empty"
    end
    return @forecastArrayHash
  end #output


  def print
    puts "Water temp forecast"
    @forecastArrayHash.each do |entry|
      dd = entry["yymmdd"].slice(4...6)
      noLeadingZeroDate = Integer(dd, 10)
      ddStringRJust = String(noLeadingZeroDate).rjust(2)
      puts "#{entry["dayEn"].ljust(10)} #{ddStringRJust} #{entry["temp"].rjust(4)} ℃"
    end #eachdo
  end #print

  def getTestData
    f = File.open(@testAddress)
    @sourceData = f.read
    f.close
  end

end #class
