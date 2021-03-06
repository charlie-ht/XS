fn web {|*|
	.d 'Open web URL'
	.a '[-t] URL'
	.c 'web'
	if {{!~ $DISPLAY ()} && {~ $*(1) -t}} {
		local (DISPLAY) {web $*(2 ...)}
	} else {
		let (error = false) {
			switch $#* (
			0 web-browser
			1 {web-browser $*}
			{throw error web 'spaces not allowed in URL'}
			)
		}
	}
}

## Sites
fn guardian {
	.d 'The Guardian'
	.c 'web'
	web https://www.theguardian.com/us
}
fn jos {
	.d 'Joel On Software'
	.c 'web'
	web https://www.joelonsoftware.com/
}
fn lwn {
	.d 'Linux Weekly News'
	.c 'web'
	web -t https://lwn.net/
}

## Web lookups
fn .web-query {|site path query|
	if {~ $#query 0} {
		web-browser $site
	} else {
		let (q) {
			q = `{echo $^query|sed 's/\+/%2B/g'|tr ' ' +}
			web-browser $site^$path^$q
		}
	}
}
fn amazon {|*|
	.d 'Search Amazon'
	.a '[QUERY]'
	.c 'web'
	.r 'github google scholar wikipedia youtube'
	.web-query https://amazon.com/ s/\?field-keywords= $*
}
fn github {|*|
	.d 'Search GitHub'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon google scholar wikipedia youtube'
	.web-query https://github.com/ search\?q= $*
}
fn google {|*|
	.d 'Search Google'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github scholar wikipedia youtube'
	.web-query https://google.com/ search\?q= $*
}
fn scholar {|*|
	.d 'Search Google Scholar'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google wikipedia youtube'
	.web-query https://scholar.google.com/ scholar\?hl=en\&q= $*
}
fn wikipedia {|*|
	.d 'Search Wikipedia'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google scholar youtube'
	.web-query https://en.wikipedia.org/ wiki/Special:Search\?search= $*
}
fn youtube {|*|
	.d 'Search YouTube'
	.a '[QUERY]'
	.c 'web'
	.r 'amazon github google scholar wikipedia'
	.web-query https://youtube.com/ results\?search_query= $*
}
