require 'json'

class FishDBChecker
  def initialize
    workingDirectory = File.dirname(__FILE__)
    directory = workingDirectory.gsub('WhenShouldIGoFishing', '')
    file = File.open("#{directory}Private/fishDB.txt")
    raw = file.read
    @fishDB = JSON.parse(raw)
  end #init

  def findAvailableFish(waterTemp)

    optimalTemp = []
    suitableTemp = []
    maybeTemp = []

    @fishDB.each do |fish, fishData|
      rating = 0
      if waterTemp > fishData["temperature range"]["suitable low"] - 2 &&
        waterTemp < fishData["temperature range"]["suitable high"] + 2
        rating += 1
      end

      if waterTemp >= fishData["temperature range"]["suitable low"] &&
        waterTemp <= fishData["temperature range"]["suitable high"]
        rating += 1
      end

      if waterTemp >= fishData["temperature range"]["optimum low"] &&
        waterTemp <= fishData["temperature range"]["optimum high"]
        rating += 1
      end

      if rating > 2
        optimalTemp.push(fishData["Romaji"])
      elsif rating > 1
        suitableTemp.push(fishData["Romaji"])
      elsif rating > 0
        maybeTemp.push(fishData["Romaji"])
      end
    end #fishDB each
    data = {
      "optimal" => optimalTemp,
      "suitable" => suitableTemp,
      "chance" => maybeTemp
    }
    return data
  end #find fish available
end #FishDBChecker

# next, to populate and also check against actual seasons fish are in/out of the bay

#a = FishDBChecker.new
#results = a.findAvailableFish(9.6)
#puts results
