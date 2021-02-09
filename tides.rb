require 'date'

class TideDataParser
  #Source:  Text data output from
  #https://www.data.jma.go.jp/gmd/kaiyou/db/tide/suisan/suisan.php

  def initialize
    @sourceFile = 'WhenShouldIGoFishing/SavedData/Tide TA 2021.txt'
    @dailyData = []
    #[[day, [time, tide]]]
    # [i][0] date String
    # [i][1][j][0] time String
    # [i][1][j][1] tide Integer
    @sortedTideMagnitudes = []
    @tideThresholds = []
  end


    def getData
    tideFile = File.open(@sourceFile)
    tideOutput = tideFile.read
    tideFile.close
    tideOutputLine = tideOutput.split("\n")

    tideOutputLine.each do |line|
      tidesTimeHeight = []
      date = Integer(line.slice(72..77).gsub(' ', '0'))

      for i in 0..7
        tideDataPoint = line.slice(80 + i * 7..86 + i * 7)

        if tideDataPoint != '9999999'
          tidesTimeHeight.push(tideDataPoint)
        end # if
      end #for loop

      tidesTimeHeight.sort!
      sortedTideTime = []
      tidesTimeHeight.each do |entry|
        time = entry.slice(0..3).gsub(' ', '0')
        height = Integer(entry.slice(4..6))
        sortedTideTime.push([time, height])
      end

      @dailyData.push([date, sortedTideTime])
    end #each do
  end #getData


  def dateFinderYYMMDD(target)
    if @dailyData.empty?
      raise StandardError.new "Data array is empty"
    end


    @dailyData.each.with_index() do |dayEntry, index|
      if String(dayEntry[0]) == target
        return index
      end
    end
    raise StandardError.new "Date not found"
    #finds the date and returns the index
    #maybe make option to return 7 days or whatever to match the water temp forecast
  end


  def tideMovementsForDay(yymmdd)
    targetDayIndex = dateFinderYYMMDD(yymmdd)
    timeTideMovements = []
    #[[day, [time, tide]]]
    # [i][0] date String
    # [i][1][j][0] time String
    # [i][1][j][1] tide Integer
    for i in 0...@dailyData[targetDayIndex][1].length
      timeA = @dailyData[targetDayIndex][1][i][0]
      tideA = tideA = @dailyData[targetDayIndex][1][i][1]
      if i == ((@dailyData[targetDayIndex][1].length) - 1)
        if @dailyData[targetDayIndex + 1].nil?
          raise StandardError.new "Next day data not available"
        end
        tideB = @dailyData[targetDayIndex + 1][1][0][1]
      else
        tideB = @dailyData[targetDayIndex][1][i + 1][1]
      end #if else

      diff = - tideA + tideB
      timeTideMovements.push([timeA, diff])
    end #for i in

    return [yymmdd, timeTideMovements]
  end #tideMagnitudesForDay


  def analyseAllTides
    @sortedTideMagnitudes = []
    # to help determine values used in tideRater
    for targetDayIndex in 0...@dailyData.length
      for i in 0...@dailyData[targetDayIndex][1].length
        timeA = @dailyData[targetDayIndex][1][i][0]
        tideA = tideA = @dailyData[targetDayIndex][1][i][1]
        if i == ((@dailyData[targetDayIndex][1].length) - 1)
          if @dailyData[targetDayIndex + 1].nil?
            #raise StandardError.new "Next day data not available"
            break
          end
          tideB = @dailyData[targetDayIndex + 1][1][0][1]
        else
          tideB = @dailyData[targetDayIndex][1][i + 1][1]
        end #if else
        @sortedTideMagnitudes.push((- tideA + tideB).abs)
      end #for i in
    end
    @sortedTideMagnitudes.sort!

    totalEntries = Float(@sortedTideMagnitudes.length)
    bottomFivePercent = @sortedTideMagnitudes[Integer(totalEntries*0.05)]
    lowerQuartile = @sortedTideMagnitudes[Integer(totalEntries*0.25)]
    median = @sortedTideMagnitudes[Integer(totalEntries*0.5)]
    upperQuartile = @sortedTideMagnitudes[Integer(totalEntries*0.75)]
    upperFivePercent = @sortedTideMagnitudes[Integer(totalEntries*0.95)]
    theOnePercent = @sortedTideMagnitudes[Integer(totalEntries*0.99)]

    @tideThresholds = [
      bottomFivePercent,
      lowerQuartile, median, upperQuartile,
      upperFivePercent, theOnePercent
    ]
  end



  def dateFormatter(dayEntry)
    monthString = String(dayEntry[0]).slice(2..3)
    monthInt = Integer(monthString, 10) #telling Integer to use base 10

    wordMonth = Date::ABBR_MONTHNAMES[monthInt]
    date = String(dayEntry[0]).slice(4..5)

    return wordMonth, date
    #return month by abbreviation and date
  end


  # return array [rating, [original array]]
  def tideRater(movement)
    if @tideThresholds.empty?
      raise StandardError.new "Run analyseAllTides first"
    end

    if movement.abs < @tideThresholds[0]      # eh
      return 0
    elsif movement.abs < @tideThresholds[1]   # small movement
      return 1
    elsif movement.abs < @tideThresholds[2]   # medium small movement
      return 2
    elsif movement.abs < @tideThresholds[3]   # medium large movement
      return 3
    elsif movement.abs < @tideThresholds[4]   # large movement
      return 4
    elsif movement.abs < @tideThresholds[5]   # huge movement
      return 5
    else                                      # end times torrential flow
      return 6
    end
  end


  def prettifyPrintAll
    @dailyData.each do |day|

      wordMonth, date = dateFormatter(day)
      tideInfoLine = ''

      day[1].each do |timeHeight|
        tideTime = timeHeight[0]
        tideHeight = String(timeHeight[1]).rjust(3, ' ')

        if tideInfoLine.length > 0
          tideInfoLine += "    #{tideHeight} at #{tideTime.insert(2, ':')}"
        else
          tideInfoLine += "#{tideHeight} at #{tideTime.insert(2, ':')}"
        end #each tideEntry

      end #each day

      puts "#{wordMonth} #{date}  #{tideInfoLine}"

    end # each do
  end #prettifyPrint

end #TideDataParser





#TEST SCRAPE TIDE
=begin
  Documentation translated:
　Hourly tide level data	：	　1-72 columns	　3 digits x 24 hours (0:00 to 23:00)

　date	：	73-78 columns	　2 digits x 3

　Point symbol	：	79-80 columns	　2-digit alphanumeric symbol



　High tide time / tide level	：	81-108 columns	　Time 4 beams (hours and minutes), tide level 3 beams (cm)
　Low tide time / tide level	：	109-136 columns	　Time 4 beams (hours and minutes), tide level 3 beams (cm)
　* If the full (low) tide is not predicted, the full (dry) tide time is set to "9999" and the tide level is set to "999".
=end



    #method to find best fishing days around weekends or work etc
    #do this outside

    #DONE method to analyse how much the tides move on average between the high and lows
    #DONE when is a big tide, and when is a small tide

    #DONE Or tide differece to next tide and whether outgoing or incoming

    #Maybe more useful information would be incoming/outgoing info only
