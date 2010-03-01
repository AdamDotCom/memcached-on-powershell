A PowerShell script that displays your Memcached cache statistics

Read more about Memcached here: http://en.wikipedia.org/wiki/Memcached

Usage:
    
  Get your Memcached Stats
    PS> Memcached-Stats '127.0.0.1' '11411'

Take a look at the screenshot: http://github.com/AdamDotCom/memcached-on-powershell/raw/master/memcached-on-powershot-screenshot.png

IMPORTANT! 'Memcached-Stats' makes use of the memcache 'stats cachedump' command which has significant performance implications. This script is for testing purposes only. DO NOT use it on production as it may lock memcache when large datasets are present. 

Deficiencies: 
  1) The Memcached 'stats cachedump' command returns at most 2MB worth of results. This can be resolved by paging through the cachedump, but hasn't been implemented in this script.
  2) I'm not sure what the signifigance of the time stamps is on a stats cachedump. I thought it represented age, but I'm not sure, related write-hosts have been commented out.
     Example:
      STATS CACHEDUMP 8 0
      ITEM tester-testie:735e9fc8-b9ef-4787-a21e-a02abc8529b3 [284 b; 1266530886 s] (what does '1266530886 s' indicate)
      END      

Adam Kahtava - http://adam.kahtava.com/ - MIT Licensed