namespace eval myapp {}

proc myapp::service {conn parms} {
	tatu::log "******** myapp starting..."
	$conn outHeader 200 {Content-Type text/plain}
	$conn out "Example output of a simple service"
}

proc myapp::bookService {conn parms} {
	tatu::log "*** method=[$conn reqCmd] conn=$conn parms=$parms"
	$conn outHeader 200 {Content-Type text/plain}
	$conn out "Plain text output from a service\nParameters: $parms"
	return 
}

tatu::addRoute "/myapp" myapp::service
tatu::addRoute "/book/:title/author/:author" myapp::bookService

error "This is an error on purpose.\nComment to remove error msg."
