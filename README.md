#Google Voice π Number Finder

This program takes a file (`pi.txt`) with an arbitrary number
of digits of pi (or any number, really) and searches Google Voice
for available numbers in a given area code that are found within those digits.
The source file can be in pretty much any format as long as the
numbers are there - it strips everything except digits before searching.

The config file (`pi.cfg`) is a simple key=value list, with the following keys:
email (your login to Google)
password (your Google password)
area\_code (the area code to search in)
country (the country code - US for the United States, not sure of others)

Good luck!  I already ran it for my area code (503) and of the 50
candidates in the first million digits, just 1 was still available.
So it did its job for me, but your luck may vary.

#Disclaimers

Of course, this program may break if Google changes its API, yadda yadda.
You use this program at your own risk.  Seeing as how it is using a
publically-accessible but internal API, it probably falls afoul of a TOS
somewhere or other.  But I can't imagine that Google could be too grumpy
about me using this to give them $30 to get a new number and keep my old one,
and I had no problem paging through 100 pages of results.
