A PowerShell script that displays your Memcached cache statistics or deletes your Memcached objects

Read more about this script here: http://adam.kahtava.com/journal/2010/03/09/memcached-on-powershell/

Read more about Memcached here: http://en.wikipedia.org/wiki/Memcached

Sample usage:

  See your Memcached Stats
    PS> memcached-stats '127.0.0.1' '11211'
    
  Remove your Memcached keys
    PS> clear-memcached-items '127.0.0.1' '11211'

View the screenshot: http://github.com/AdamDotCom/memcached-on-powershell/blob/master/memcached-on-powershot-screenshot.png

IMPORTANT! 'Memcached-Stats' makes use of the memcache 'stats cachedump' command which has significant performance implications. This script is for testing purposes only. DO NOT use it on production as it may lock Memcached.

Deficiencies: 
  1) The Memcached 'stats cachedump' command returns at most 2MB worth of results.

Adam Kahtava - http://adam.kahtava.com/ - MIT Licensed