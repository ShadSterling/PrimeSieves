#!/usr/bin/ruby -wKU
# encoding: UTF-8


#5:
# • progress indicators
# • where do the merges happen?
# • special iterator for gaps with to_sum, etc
# • methods for sum-by-index and index-by-sum (add sum information to merge list?)
# • faster way to seek: we know the sum over the length of the prior sieve; we know something about the sum between merges
# • re-merge handling of primes?
# • build sieve on-demand rather than all at once
# • inspect similarities by section; use merges as section boundaries
# • extend primes to speed sieve building by multiplying next exclusion only by higher primes
# • watch successive rations of counts per gap length (e.g. for gaps of 2: 1,1,3,15,135,1485,22275,378675,7952175, ...)
#                                                           successive ratios: 1,3,5,9,11,15,17,21,...
#                                                           differences: 2,2,4,2,4,2,4,...


$stdout.sync = true #don't buffer output

depth = 12 #generate this many sieves


###-----------------------------------------------------------------------------------
###
###  supporting classes
###

#sorted array; used for merge lists
class Sorted
protected
  def _become(array); raise unless []==@array; @array = array; self; end
public
  def initialize(array=[]); @array = array.sort; end

  def alloc(n)
    if length < n then
      range = (length..(n-1))
      @array.fill(nil,range)
      @array.slice!(range)
    end
    self
  end

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

#adding to default array class
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


###-----------------------------------------------------------------------------------
###
###  gap class
###

class Gaps #each instance represents a series of gaps between n-rough numbers
  @@sieves = [nil] #list of existing instances; there is no zeroith sieve
  @@primes = [nil,2,3,5,7] #list of primes - extended as a side effect of generating sieves

  #generate & return the next sieve (class method)
  def self.next; self.new; end

  #generate & return the next sieve (instance method)
  def next; self.class.next; end

  #populate new sieve pased on prior sieve; note this is not thread safe
  def initialize
    @prime = @@sieves.length #this sieve excludes multiples through @@primes[@prime]
    if 1 == @prime then #the first one isn't based on a prior sieve
      @cut = 2     #excludes primes through this (==@@primes[@prime])
      @length = 1  #count of gaps in one cycle
      @sum = 2     #sum of gaps in one cycle
      @merge = nil #no prior sieve, no merges
      @dist = [[1,1.0]] #distribution of gaps: @dist[0] indicates gap size 2 occurs once for 100% of sieve
    elsif 2 == @prime #the generator algorithm doesn't work yet
      @cut = 3     #excludes primes through this (==@@primes[@prime])
      @length = 2  #count of gaps in one cycle
      @sum = 6    #sum of gaps in one cycle
      @merge = [0].to_sorted #one merge at 0+1
      @dist = [[1,0.5],[1,0.5]] #distribution of gaps: 2 occurs once for 50%, 4 occurs once for 50%
    else
      mcount = prior.length/2 #the number of merges is the number of entries on the prior sieve; we only store half because it's a pallendrome
      @prime = prior.num+1  #we're excluding the next prime number
      @cut = 1+prior[0]     #this is the prime we're removing multiples of, ==@@primes[@prime] (which is already set)
      @length = prior.length*prior[0] #count of gaps in one cycle
      @sum = prior.sum*@cut #the sum of gaps in one cycle
      @merge = Sorted.new.alloc(mcount) #the list of gaps in the first half of the cycle --- this will change
      @dist = [nil]*prior.count  #dstribution of gaps --- this will change
      primeto = @cut**2 #least possible nonprime
      remove = @cut     #first number to remove (merge gaps above & below)
      rnext = @prime     #index to next prime multiple to remove
      rough = 1 #gaps start from here
      carry = 0 #carry for merges
      checksum = 0 #check sum; should == @sum when finished
      checkcut = @cut #check remove
      #puts "looking for #{remove}"
      gapcount = length/2-1
      g = 0; j = 0
      prior.infinate_each_with_index do |g,z|
        rough += g
        while rough > remove do
          if rnext < @@primes.length then
            remove = @cut * @@primes[rnext]
            #puts "#{@cut} * #{@@primes[rnext]} (##{rnext}) = #{remove} (##{rnext})"
            rnext += 1
          else
            #puts "#{@cut} + #{remove} = #{remove + @cut}"
            remove += @cut
          end
          #puts "looking for #{remove}, carrying #{carry}"
        end
        while rough > checkcut do
          checkcut += @cut
        end
        unless 0 == carry then
          puts " !!  consecutive carry building sieve #{@prime} removing rough number #{rough}, carry=#{carry}" if remove == rough
          g += carry
          carry = 0
        end
        #puts "#{i}: #{rough}\t#{@gaps.inspect}"
        if rough == remove then
          carry = g
          @merge << j
          #puts "removed #{rough} at #{j}->#{i} (#{@merge.length-1}=>#{j}), carrying #{carry}"
        else
          if rough == checkcut then
            puts " !!  missed removal building sieve #{@prime} missed rough number #{rough}, remove=#{remove}; primeto=#{primeto}, prime ceiling = #{@cut*@@primes[-1]}, rnext=#{rnext}/#{@@primes.length}"
          end
          e = g/2-1
          if nil == @dist[e] then
            @dist[e] = 1
          else
            @dist[e] += 1
          end
          @@primes << rough if rough < primeto and rough > @@primes[-1]
          checksum += g
          #puts "included #{rough} at #{j}->#{i} (#{checksum-g+1}+#{g}=#{rough}; waiting for #{remove})"
          self[j]
          j += 1
          break if j > gapcount
        end
      end
      #unless RUBY_PLATFORM =~ /mswin32/ then
      #  i = @gaps.length
      #  watch.run
      #  watch.join
      #end
      #puts @gaps.inspect
      @dist[1] -= 1 #take out the extra 4 in the middle
      0.upto(@dist.length-1) do |i|
        d = @dist[i]
        d = 0 if nil == d
        d *= 2 #'cause we only did one half
        d += 1 if [0,1].include?(i) #an extra 2 on the end & an extra 4 in the middle
        if 0 == d then
          @dist[i] = [0, 0]
        else
          @dist[i] = [d, d.to_f/length]
        end
      end
      if g != 4 then
        puts " !! middle isn't 4 building sieve #{@prime}: #{g} != 4\n"
      end
      checksum = (checksum-4) * 2 + 6 #checksum covers half of the pallendrome, excluding the middle (4) and the top (2)
      if checksum != @sum then
        puts " !! SUM ERROR building sieve #{@prime}: #{checksum} != #{@sum}\n"
      end
    end
    @@sieves[@prime] = self
    @merge.freeze
    self.freeze
  end

  attr_reader :sum, :length
  def num; @prime; end #the index of the highest excluded prime
  def count(e=nil); nil==e ? @dist.length : ( i=e/2-1;d=@dist[i];nil==d ? nil : d[0] ); end
  def less; if @prime > 2; @merge.length*2; else 1; end; end
  def prior; @@sieves[@prime-1]; end

  def [](i) #the ith gap between rough numbers
    #p = 4
    if i >= 0 then
      j=i.divmod(length)[1]
      if j == length-1 then
        #puts "##{@prime}[#{i}/#{length-1}->#{j}] = 2  (top)" if @prime >= p
        r = 2
      elsif j == length/2-1 then
        #puts "##{@prime}[#{i}/#{length-1}->#{j}] = 4  (mid)" if @prime >= p
        r = 4
      #elsif j == 0 then
      #  a = prior[0]; b = prior[1]; r = a+b
      #  puts "##{@prime}[#{i}/#{length-1}->#{j}] = ##{@prime-1}[0+1] = #{a}+#{b} = #{r}  (first)" if @prime >= p
      elsif j < length/2-1 then
        m = @merge.index_or_below(j)
        k = j + m
        if @merge[m] == j then
          a = prior[k]; b = prior[k+1]; r = a+b
          #puts "##{@prime}[#{i}/#{length-1}->#{j}] = ##{@prime-1}[#{k}+#{k+1}] = #{a}+#{b} = #{r}  (merge)" if @prime >= p
        else
          k += 1
          r = prior[k]
          #puts "##{@prime}[#{i}/#{length-1}->#{j}] = ##{@prime-1}[#{k}] = #{r}  (passthrough)" if @prime >= p
        end
      else # j > length/2
        k = length-2-j
        r = self[k]
        #puts "##{@prime}[#{i}/#{length-1}->#{j}] = ##{@prime}[#{k}] = #{r}  (mirror)" if @prime >= p
      end
    else
      raise "negative index"
    end
    r
  end

  def infinate_each
    infinate_each_with_index do |g,i|
      yield g
    end
  end

  def infinate_each_with_index #iterate forever over gaps
    if 1 == @prime then
      i = 0
      while true do
        #puts "##{@prime}[#{i}/0] = 2"
        yield 2, i
        i += 1
      end
    elsif 2 == @prime then
      i = 0
      while true do
        #puts "##{@prime}[#{i}/1] = 4"
        yield 4, i
        i += 1
        #puts "##{@prime}[#{i}/1] = 2"
        yield 2, i
        i += 1
      end
    else
      #p=4
      merge = 0
      carry = 0
      i = 0; j = 0
      mid = length/2-1
      top = length-2
      #puts "#{@prime} > #{prior.inspect}"
      prior.infinate_each_with_index do |g,z|
        if i < mid and merge < @merge.length and i == @merge[merge] then
          #puts "##{@prime} merge into #{i}/#{mid} = #{g}  .. #{carry},#{merge},#{@merge[merge].inspect},#{top-i}" if @prime >= p
          carry = g
          merge += 1
        elsif i > mid and merge >= 0 and top-i == @merge[merge]
          #puts "##{@prime} merge into #{i}/#{mid} = #{g}  .. #{carry},#{merge},#{@merge[merge].inspect},#{top-i}" if @prime >= p
          carry = g
          merge -= 1
        else
          #puts "##{@prime}[#{i}/#{mid}] = #{g+carry}\t.. #{g}+#{carry},#{merge},#{@merge[merge].inspect},#{top-i}" #if @prime >= p
          if 0 != carry then
            g += carry
            carry = 0
          end
          yield g, j
          i += 1; j += 1
          if i == mid then
            merge -= 1
          elsif i == length
            i = 0
            merge += 1
          end
          raise if i == 0 and merge != 0
        end
      end
    end
    nil
  end

  def to_a( max )
    max = [length,max].min
    a = [nil]*max
    stop = max-1
    infinate_each_with_index do |g,i|
      a[i] = g
      break if i >= stop
    end
    a << :etc if length > max
    a
  end

  def info
    r = "##{@prime}:\t#{self.to_a(48).inspect}\n\t"
    if 1==@prime then
      r += "1 entry, 0 merges, sum = 2"
    else
      r += "#{length} entries, #{less} merges, sum = #{@sum}"
    end
    @dist.each_with_index do |d,i|
      n,p = *d
      if 0 == p then
        r += "\n\t#{2*(1+i)}:  ABSENT"
      else
        r += "\n\t#{2*(1+i)}: #{n}\t#{p}"
      end
    end
    r
  end


end


###-----------------------------------------------------------------------------------
###
###  entry point
###

puts Time.now
puts

depth.times do
  g = Gaps.next
  puts g.info
  #puts g.to_a.inspect
  puts Time.now
  puts
end

puts "done"
