# Copyright Ndivi Ltd.
class Batch < Ndivi::BatchBase
  def self.run(stage)
    Batch.new(stage).process
  end
 
  def process
    case stage
      when 1 then execute(:name=>"example 1", :every=> 1.year) {print "doing stuff once a year\n"}
      when 2 then execute(:name=>"example 2") {print "doing other stuff every time\n"}
      else exit(42)
    end
  end
end
