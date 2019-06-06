#!/usr/bin/ruby -wKU
# encoding: UTF-8


#12:
# a. adjust loops so output messages all go with a candidate
# b. start with low primes in test
# c. start with high primes in factor
# d. duplicate test in extend_primes, but don't divide by excluded primes
#13:
# a. extend_sieve: composites to exclude need only be prime multiples of newprime

$stdout.sync = true
#$verbose = true
$verbose = false
iterations = 2
pinginterval = 100

class Sorted
protected
  def _become(array); raise unless []==@array; @array = array; self; end
public
  def initialize(array=[]); @array = array.sort; end

  def [](index);
    case index
      when Range
        r = self.class.new._become(@array[index])
      else
        r = @array[index];
    end
    raise index.class.to_s if r.class == Array
    r
  end
  def <<(obj); self.insert!(obj); end
  def length; @array.length; end
  def sum; @array.sum; end

  def shift; @array.shift; end

  def insert!( obj )
    r = [obj]
    if 0 != @array.length
      #TODO: use <=>, force unique entries.
      case obj <=> @array[-1]
        when -1 #it's in the range of the array
          case obj <=> @array[0]
            when -1
                r = r + @array
            when 0
              r = @array
            when 1
              raise r = @array.insert( self.index( obj, true ), obj )
            else
              raise "invalid test result"
          end
        when 0
          r = @array
        when 1
          r = @array + r
        else
          raise "invalid test result"
      end
    end
    @array = r
    self
  end

  #finds the index of this object, returns nil if not included
  def index( obj )
    #puts "seek: find entry equal to #{obj}"
    if @array.length == 0
      index = nil
    elsif @array[-1] < obj #obj is above highest entry
      index = nil
    elsif @array[0] > obj #obj is below lowest entry
      index = nil
    else
      bot = 0
      top = @array.length-1
      index = nil #ensure scope
      while true do
        range = top-bot
        if range > 1 #if there are more than two left
          index = bot+range.divmod(2)[0] #test the middle one (or the lower of the middle two)
        elsif range == 1 #if there are two left
          index = bot #test the lower one
        else #if there's only one left
          if @array[bot] == obj #it's the one we want
            index = bot
          else #or the one we want isnt here
            index = nil 
          end
          break #and we're done
        end
        check = @array[index]
        #puts "seek: within #{bot}..#{top} (#{range}), testing ##{index}: #{check} <=> #{obj}"
        if check > obj #if the midpoint is too high
          top = index #move down the top
        elsif check < obj #if the midpoint is too low,
          bot = index+1 #move up the bottom
        else #if we've hit the magic number
          break #we're done
        end
      end
    end
    #puts (index==nil) ? "seek: entry #{obj} not found" : "seek: entry #{obj} is #{@array[index].inspect} at index #{index.inspect}"
    index
  end

  #finds the index of this object, or the next higher object if this one is not included
  def index_or_above( obj )
    #puts "seek: find entry at or above #{obj}"
    if @array.length == 0
      index = nil
    elsif @array[-1] < obj #obj is above highest entry
      index = nil
    elsif @array[0] >= obj #obj is at or below lowest entry (note this covers case where there's only one entry)
      index = 0
    else
      bot = 0
      top = @array.length-1
      index = nil #ensure scope
      while true do
        range = top-bot
        if range > 1 #if there are more than two left
          index = bot+range.divmod(2)[0] #test the middle one (or the lower of the middle two)
        elsif range == 1 #if there are two left
          index = bot #test the lower one
        else #if there's only one left
          index = bot #that's the one we want
          break       #and we're done
        end
        check = @array[index]
        #puts "seek: within #{bot}..#{top} (#{range}), testing ##{index}: #{check} <=> #{obj}"
        if check > obj #if the midpoint is too high
          top = index #move down the top
        elsif check < obj #if the midpoint is too low,
          bot = index+1 #move up the bottom
        else #if we've hit the magic number
          break #we're done
        end
      end
    end
    puts index==nil ? "seek: entry at or above #{obj} not found" : "seek: entry at or above #{obj} is #{@array[index].inspect} at index #{index.inspect}"
    index
  end

  #finds the index of this object, or the next lower object if this one is not included
  def index_or_below( obj )
    #puts "seek: find entry at or below #{obj}" #+ " in #{@array.inspect}"
    if @array.length == 0
      index = nil
    elsif @array[0] == obj #obj is lowest entry
      index = 0
    elsif @array[-1] <= obj #obj is at or above highest entry (note this covers case where there's only one entry)
      index = @array.length-1
    else
      bot = 0
      top = @array.length-1
      index = nil #ensure scope
      while true do
        range = top-bot
        if range > 1 #if there are more than two left
          index = bot+range.divmod(2)[0] #test the middle one (or the lower of the middle two)
        elsif range == 1 #if there are two left
          index = top #test the higher one
        else #if there's only one left
          index = bot #that's the one we want
          break       #and we're done
        end
        check = @array[index]
        #puts "seek: within #{bot}..#{top} (#{range}), testing ##{index}: #{check} <=> #{obj}"
        if check > obj #if the midpoint is too high
          top = index-1 #move down the top
        elsif check < obj #if the midpoint is too low,
          bot = index #move up the bottom
        else #if we've hit the magic number
          break #we're done
        end
      end
    end
    #puts (index==nil) ? "seek: entry at or below #{obj} not found" : "seek: entry at or below #{obj} is #{@array[index].inspect} at index #{index.inspect}"
    index
  end

end

class Array
  def sum
    s = 0
    self.each do |e|
      s += e
    end
    s
  end
  def to_sorted
    Sorted.new(self)
  end
end

class Primes
  #no instances of this.
  def new; raise; end

  #primes
  @@prime_index = [2,3,5,7,11].to_sorted #of known index ([n]=>nth prime; 2 is the zeroth prime)
  @@prime_known = [].to_sorted #above known indexes (sorted)
  @@prime_skip_step = 2 #next candidate after highest indexed prime is this step in sieve
  #sieve 1
  @@sieve = [6,4,2,4,2,4,6,2] #entries (not sorted!)
  @@sievesum = @@sieve.sum #30 #sum of entries (range covered by sieve); this is the primorial of highest excluded prime
  @@sieve_prime = 2 #index of highest prime that has been excluded
  @@sieve_skip_step = 2 #start candidate is at this entry in sieve
  @@sieve_skip_sum = 10 #sum of skipped sieve entries
  #operation status
  @@status = [nil,nil] #prime extension, sieve extension

  def self.extend_sieve
    newprime = 1+@@sieve[0] #== @@prime_index[@@sieve_prime]
    exclude = newprime**2 #candidates below this are prime (set to nil after passing)
    sumstop = newprime*@@sievesum #sum of new sieve
    #puts "extend: excluding #{newprime}; candidates below #{exclude} are prime, new sieve will have sum #{sumstop}"
    sievestep = @@sieve_skip_step #start at predetermined step in sieve
    newsieve = [@@sieve[0]+@@sieve[1]] + @@sieve[2...(sievestep)] #merge first entries, copy skipped entries
    newsum = @@sieve_skip_sum #merging entries doesn't change sum
    #puts "extend: new sieve skips #{newsum} to step #{sievestep}, so begins with #{newsieve.length} entries with sum #{newsum}"
    prior = 1+newsum
    candidate = prior+@@sieve[sievestep]
    #puts "extend: after skip next candidate is #{candidate} and prior \"candidate\" was #{prior} (step #{sievestep} is of size #{@@sieve[sievestep]})"
    #ensure scope
    sieve_step=nil
    sieve_sum=nil
    prime_step=nil
    #@@status[1] = [1, newsum, sumstop]
    @@status[1] = [1, newsieve.length, @@sieve.length*@@sieve[0]]
    badcount = 0

    #first loop: all candidates are indexed primes
    while candidate <= @@prime_index[-1] and candidate < exclude do
      message = "extend/1: "
      gap = candidate-prior
      newsum += gap
      #@@status[1][1] = newsum
      newsieve << gap
      @@status[1][1] = newsieve.length
      message += "candidate #{candidate} is GOOD (step #{newsieve.length-1} size #{gap} sum #{newsum} of #{sumstop})"
      message += "; is indexed prime"
      prior = candidate
      sievestep += 1
      if sievestep == @@sieve.length
        sievestep = 0
        message += ";  old sieve rolls over"
      end
      puts message if $verbose
      candidate += @@sieve[sievestep]
    end

    #second loop: all candidates are unindexed primes
    @@status[1][0] = 2
    if candidate > @@prime_index[-1] #prime_step is always nil here
      while candidate < exclude do
        message = "extend/2: "
        gap = candidate-prior
        newsum += gap
        #@@status[1][1] = newsum
        newsieve << gap
        @@status[1][1] = newsieve.length
        message += "candidate #{candidate} is GOOD (step #{newsieve.length-1} size #{gap} sum #{newsum} of #{sumstop})"
        if @@prime_known[0] == candidate
          message += "; is known prime, now ##{@@prime_index.length}"
          @@prime_known.shift
        else
          message += "; is new prime ##{@@prime_index.length}"
        end
        @@prime_index << candidate
        prior = candidate
        sievestep += 1
        if sievestep == @@sieve.length
          sievestep = 0
          message += "; old sieve rolls over"
        end
        puts message if $verbose
        candidate += @@sieve[sievestep]
      end
      prime_step = (newsum==sumstop) ? 0 : newsieve.length #to replace @@prime_skip_step
#      prime_sum = newsum #to replace @@prime_skip_sum
      #puts "extend/p: next prime extension starts with step #{prime_step}"
    end

    #at this point candidate=newprime**2, so we reject it and set up the next exclusion
    message = "extend/~: candidate #{candidate} is BAD (#{candidate} = #{newprime} squared)"
    sieve_step = newsieve.length #to replace @@sieve_skip_step
    sieve_sum = newsum #to replace @@sieve_skip_sum
    message += "; starts next extension (skip #{sieve_sum} to step #{sieve_step})"
    primestep = @@sieve_prime+3 #multiples of newprime below newprime**2 are excluded by old sieve
    other = @@prime_index[primestep-1]
    exclude = newprime*other
    message += "; next composite is #{exclude} = #{newprime}*#{other}"
    sievestep += 1
    if sievestep == @@sieve.length
      sievestep = 0
      message += ";  old sieve rolls over"
    end
    puts message if $verbose
    candidate += @@sieve[sievestep]

    #third loop: prime candidates are already indexed, excluding by prime factor
    @@status[1][0] = 3
    while candidate <= @@prime_index[-1] and primestep < @@prime_index.length and newsum < sumstop
      message = "extend/3: "
      if candidate == exclude
        message += "candidate #{candidate} is BAD (#{candidate} = #{newprime}*#{other})"
        other = @@prime_index[primestep]
        exclude = newprime*other
        message += "; next composite is #{exclude} = #{newprime}*#{other}"
        primestep += 1
      else
        gap = candidate-prior
        newsum += gap
        #@@status[1][1] = newsum
        newsieve << gap
        @@status[1][1] = newsieve.length
        message += "candidate #{candidate} is GOOD (step #{newsieve.length-1} size #{gap} sum #{newsum} of #{sumstop})"
        prior = candidate
      end
      sievestep += 1
      if sievestep == @@sieve.length
        sievestep = 0
        message += "; old sieve rolls over"
      end
      puts message if $verbose
      candidate += @@sieve[sievestep]
    end
    if candidate > @@prime_index[-1] and nil == prime_step
      prime_step = (newsum==sumstop) ? 0 : newsieve.length #to replace @@prime_skip_step
#      prime_sum = newsum #to replace @@prime_skip_sum
      #puts "extend/p: next prime extension starts with step #{prime_step}"
    end

    #fourth loop: prime candidates are unknown, excluding by prime factor
    @@status[1][0] = 4
    if candidate > @@prime_index[-1]
      while primestep < @@prime_index.length and newsum < sumstop
        message = "extend/4: "
        if candidate == exclude
          message += "candidate #{candidate} is BAD (#{candidate} = #{newprime}*#{other})"
          other = @@prime_index[primestep]
          exclude = newprime*other
          message += "; next composite is #{exclude} = #{newprime}*#{other}"
          primestep += 1
          message += " (end of indexed primes)" unless primestep < @@prime_index.length
        else
          gap = candidate-prior
          newsum += gap
          #@@status[1][1] = newsum
          newsieve << gap
          @@status[1][1] = newsieve.length
          message += "candidate #{candidate} is GOOD (step #{newsieve.length-1} size #{gap} sum #{newsum} of #{sumstop})"
          prior = candidate
        end
        sievestep += 1
        if sievestep == @@sieve.length
          sievestep = 0
          message += "; old sieve rolls over"
        end
        puts message if $verbose
        candidate += @@sieve[sievestep]
      end
    end

    #fifth loop: prime candidates are unknown, excluding by any factor
    @@status[1][0] = 5
    while newsum < sumstop
      message = "extend/5: "
      if candidate != exclude
        gap = candidate-prior
        newsum += gap
        #@@status[1][1] = newsum
        newsieve << gap
        @@status[1][1] = newsieve.length
        message += "candidate #{candidate} is GOOD (step #{newsieve.length-1} size #{gap} sum #{newsum} of #{sumstop})"
        prior = candidate
      else
        message += "candidate #{candidate} is BAD (#{candidate} = #{newprime}*#{other})"
      end
      if candidate >= exclude
        exclude += newprime
        message += "; next composite is #{exclude} = #{newprime}*#{other+=1}"
        primestep += 1
      end
      sievestep += 1
      if sievestep == @@sieve.length
        sievestep = 0
        message += "; old sieve rolls over"
      end
      puts message if $verbose
      candidate += @@sieve[sievestep]
    end

    @@sieve_prime += 1
    @@sieve = newsieve #entries
    @@sievesum = newsum #sum of entries (range covered by sieve); this is the primorial of highest excluded prime
    @@sieve_skip_step = sieve_step #skip to this entry when extending sieve
    @@sieve_skip_sum = sieve_sum #sum of skipped sieve entries
    @@prime_skip_step = prime_step #skip to this entry when extending primes
#    @@prime_skip_sum = prime_sum #sum of skipped sieve entries
    @@status[1] = nil
  end

  def self.extend_primes( upto=nil )
    upto = @@prime_index[-1] + @@sievesum unless upto != nil
    sievestep = @@prime_skip_step
    candidate = @@prime_index[-1]+@@sieve[sievestep]
    tested = 0
    newcount = 0
    @@status[0] = [candidate, upto]
    while @@prime_index[-1] < upto do
      message = "extend to #{upto}: candidate #{candidate} (position #{sievestep} of #{@@sieve.length})"
      tested += 1
      if candidate == @@prime_known[0] #candidate is next known prime
        message += ";  prime ##{@@prime_index.length} from known unindexed"
        @@prime_index << @@prime_known.shift
        newcount += 1
      else #do real test
        isqrt = self.isqrt( candidate ) #all factors will be between the highest excluded prime and the candidates square root
        r = true
        (@@sieve_prime+1).upto(@@prime_index.index_or_below( isqrt )) do |primestep|
          prime = @@prime_index[primestep]
          other,remainder = candidate.divmod(prime)
          if remainder == 0
            message += ";  composite with factors #{prime} and #{other}"
            r = false
            break
          end
        end
        if r == true
          message += ";  prime ##{@@prime_index.length} by test"
          @@prime_index << candidate
          newcount += 1
        end
      end
      message += ";  #{tested} tested, #{newcount} found"
      sievestep += 1
      if sievestep == @@sieve.length
        sievestep = 0
        message += ";  sieve rolls over"
      end
      candidate += @@sieve[sievestep]
      @@status[0][0] = candidate
      puts message if $verbose
    end
    @@prime_skip_step = sievestep
    @@status[0] = nil
    newcount #return the number of primes found
  end
  
  def self.test( candidate )
    r = nil
    if candidate <= @@prime_index[-1]
      if candidate == @@prime_index[-1] #candidate is highest indexed prime
        r = true
      else #candidate is within indexed primes
        t = @@prime_index.index( candidate )
        r = (t != nil)
      end
    else  #candidate is above highest indexed prime
      t = @@prime_known.index( candidate )
      if t != nil #candidate is a known prime
        r = true
      else #do real test
        isqrt = self.isqrt( candidate )
        while @@prime_index[-1] < isqrt
          self.extend_primes
        end
        primestep = @@prime_index.index_or_below( isqrt ) #start looking for factors at the square root
        while primestep >= 0 do
          prime = @@prime_index[primestep]
          other,remainder = candidate.divmod(prime)
          if remainder == 0
            #puts "test: #{prime} is a factor of #{candidate}; #{candidate} = #{prime}*#{other}+#{remainder}"
            r = false
            break
          end
          #puts "test: #{prime} is not a factor of #{candidate}; #{candidate} = #{prime}*#{other}+#{remainder}"
          primestep -= 1
        end
        unless r == false
          r = true
          @@prime_known << candidate
        end
      end
    end
    #puts "test: #{candidate} is #{r ?"":"NOT "}prime"
    r
  end
  
  def self.isqrt( square ) #Thanks WikiPedia!
    bits = (square.size)*8
    while true do
      bits -= 1
      break if square[bits] != 0
    end
    estimate = (2**(bits/2))
    test = 1
    while test >= 1 do
      newestimate = (estimate+square/estimate)/2
      test = newestimate - estimate
      estimate = newestimate
    end
    answer = estimate.to_i
    #puts "isqrt: answer: #{square} >= #{answer}**2"
    answer
  end

  def self.info
    info = ""
    info << "primes indexed through ##{@@prime_index.length-1}, which is #{@@prime_index[-1]} (next candidate is #{@@prime_index[-1]+@@sieve[@@prime_skip_step]} at step #{@@prime_skip_step})\n"
    info << "sieve excludes through ##{@@sieve_prime}(=#{@@prime_index[@@sieve_prime]}), has #{@@sieve.length} entries with sum #{@@sievesum} covering 1..#{1+@@sievesum} (next candidate is #{1+@@sieve_skip_sum+@@sieve[@@sieve_skip_step]} at step #{@@sieve_skip_step})\n"
    info
  end
  def self.progress #shows progress of extending sieve and/or primes
    "primes #{nil==@@status[0]?"idle":"at #{@@status[0][0]} to #{@@status[0][1]} (#{sprintf("%1.4f",@@status[0][0].to_f/@@status[0][1])})"}; sieve #{nil==@@status[1]?"idle":"loop #{@@status[1][0]} at #{@@status[1][1]} to #{@@status[1][2]} (#{sprintf("%1.4f",@@status[1][1].to_f/@@status[1][2])})"}"
    #"primes #{nil==@@status[0]?"idle":"at #{@@status[0][0]} to #{@@status[0][1]} (#{@@status[0][0].to_f/@@status[0][1]})"}; sieve #{nil==@@status[1]?"idle":"loop #{@@status[1][0]} at #{@@status[1][1]} to #{@@status[1][2]} (#{sprintf("%1.4f",@@status[1][1]/@@status[1][2])})"}"
  end
end

puts " * #{Time.now}:  Initial state:"
puts Primes.info
puts
puts

pinger = Thread.new do
	while true do
		sleep pinginterval
		puts " + #{Time.now}:  progress: " + Primes.progress
	end
end

2	.times do
  puts " * #{Time.now}:  Extending sieve..."
  Primes.extend_sieve
  puts Primes.info
  puts
end
puts " * #{Time.now}:  Extending primes..."
Primes.extend_primes
puts Primes.info
puts

$verbose = true
puts " \" (Begin Verbose)"
puts

puts " * #{Time.now}:  Extending sieve..."
Primes.extend_sieve
puts Primes.info
puts
puts " * #{Time.now}:  Extending primes..."
Primes.extend_primes
puts Primes.info
puts

$verbose = false
puts " \" (End Verbose)"
puts

iterations.times do
  puts " * #{Time.now}:  Extending sieve..."
  Primes.extend_sieve
  puts Primes.info
  puts
  puts " * #{Time.now}:  Extending primes..."
  Primes.extend_primes
  puts Primes.info
  puts
end

pinger.kill

puts " * #{Time.now}:  Done."
puts

