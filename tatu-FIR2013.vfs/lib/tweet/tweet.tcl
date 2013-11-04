#!/usr/bin/env tclsh
package provide tweet 1.0
package require oauth

namespace eval tweet {
	variable consumer_key "WQhs6ENw0VEJppkD7EaCdw"
	variable consumer_secret "jssSKdd6VoV5S347Ce4V7NV4MpOxCF2grtr6eZi3U"
	variable oauth_token "27368825-eA3jbyWvrfZNukqGwEwEWNZAmHFBpDIPokWZ3Snj4"
	variable oauth_token_secret "0mbliX2oD5PcXn2E4q1l5HnE0auNlHu7eGgiGibHs"
}

proc tweet::tweet {msg} {
	variable consumer_key 
	variable consumer_secret
	variable oauth_token 
	variable oauth_token_secret
	set r [oauth::query_api http://api.twitter.com/1/statuses/update.json \
		$consumer_key $consumer_secret POST $oauth_token $oauth_token_secret \
		[list status $msg]]
	return $r
}

#puts [tweet [join $argv " "]]


