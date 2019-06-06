# Prime Sieves

When i went back to school and took Calculus 2, I found I had a harder time with factoring polynomials than most of what was intended as new material.  As a Computer Science major I thought the right way to learn how to factor polynomials would be to write a program to do it.  But factoring polynomials seemed complicated enough that I should start with a simpler case, and the base case of factoring seemed to be factoring natural numbers, so I figured I'd start with that.

Yeah, I had no idea.

To find factors I figured I'd need to be able to find primes, and while I initially thought it would be fine to do it the naive way
```
while primes.max < target
	candidate += 1
	primes.addIfPrime candidate
end
```
I quickly decided it was silly to check all the even numbers
```
while primes.max < target
	candidate += 2
	primes.addIfPrime candidate
end
```
And then that it would be silly to check for multiples of 3
```
while primes.max < target
	[4,2].each do |gap|
		candidate += gap
		primes.addIfPrime candidate
	end
end
```
And multiples of 5
```
while primes.max < target
	[6, 4, 2, 4, 2, 4, 6, 2].each do |gap|
		candidate += gap
		primes.addIfPrime candidate
	end
end
```
And before I knew it I was totally sidetracked into investigating these sequences of candidate gaps.

These are the little programs I wrote to implement and test my thinking about this, mostly in 2007-2008, updated in 2010, and now tweaked to work with newer versions of Ruby.
