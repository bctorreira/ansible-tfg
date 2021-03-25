# Ansible managed file
vcl 4.0;
# Based on: https://github.com/mattiasgeniar/varnish-4.0-configuration-templates/blob/master/default.vcl

import std;
import directors;
#
# List of backend servers
# #############################################################################
include "conf.d/backends.vcl";


# List of IPs and domains that can perform PURGE and BAN requests
# ##############################################################################
include "conf.d/acls.vcl";

#########
#
# vcl_init()
#
# Initialize the VCL
#
# Called when VCL is loaded, before any requests pass through it.
# Typically used to initialize VMODs.
#
#########
sub vcl_init {
  new vdir = directors.round_robin();
    vdir.add_backend(app02fra1doc);
    vdir.add_backend(app03fra1doc);
}
#########
#
# vcl_recv()
#
# Receives and modifies the incoming request
#
# Called at the beginning of a request, after the complete request has been received and parsed.
# Its purpose is to decide whether or not to serve the request, how to do it, and, if applicable,
# which backend to use.
# also used to modify the request
#
#########
sub vcl_recv {
# Backend settings
# ##########################################################################
  set req.backend_hint = vdir.backend(); # send all traffic to the vdir director

# Normalize the header, remove the port (in case you're testing this on various TCP ports)
#set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

# Normalize the query arguments
    set req.url = std.querysort(req.url);

# Return 403 Not authorized if User-Agent is PhantomJS
  if (req.http.User-Agent ~ "PhantomJS") {
    return(synth(403,"Not authorized"));
  }

#
# BAN requests handling
# ##########################################################################
  if (req.method == "BAN") {
    if (!client.ip ~ purge) {
      return(synth(405, "Ban not allowed from " + client.ip));
    } else {
      if (req.http.X-Varnish-Ban) {
        ban(req.http.X-Varnish-Ban);

        return(synth(200, "Ban added:" + req.http.X-Varnish-Ban));
      } else {
        return(synth(412, "No Ban Specified"));
      }
    }
  }

#
# Modifying and preparing the request to be handled
# ##########################################################################
  if (req.restarts == 0) {
    if (req.http.X-Forwarded-For) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }

    if (req.http.X-Forwarded-Proto == "https" ) {
      set req.http.X-Forwarded-Port = "443";
    } else {
      set req.http.X-Forwarded-Proto = "http";
      set req.http.X-Forwarded-Port = "80";
    }
  }

# First remove the Google Analytics added parameters, useless for our backend
  if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=") {
    set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
    set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
    set req.url = regsub(req.url, "\?&", "?");
    set req.url = regsub(req.url, "\?$", "");
  }

# Strip hash, server doesn't need it.
  if (req.url ~ "\#") {
    set req.url = regsub(req.url, "\#.*$", "");
  }

# Strip a trailing ? if it exists
  if (req.url ~ "\?$") {
    set req.url = regsub(req.url, "\?$", "");
  }

# This code must be included
# Cache /search/google
  if (req.url ~ "^/search/google.*") {
    set req.url = regsub(req.url, "\?.*", "");
  }

# Some generic cookie manipulation, useful for all templates that follow
# Remove the "has_js" cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

# Remove any Google Analytics based cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

# Remove DoubleClick offensive cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");

# Remove the Quant Capital cookies (added by some plugin, all __qca)
  set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

# Remove the AddThis cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");

# Remove a ";" prefix in the cookie if present
  set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

# Are there cookies left with only spaces or that are empty?
  if (req.http.cookie ~ "^\s*$") {
    unset req.http.cookie;
  }

# Large static files are delivered directly to the end-user without
# waiting for Varnish to fully read the file first.
# Varnish 4 fully supports Streaming, so set do_stream in vcl_backend_response()
  if (req.url ~ "^[^?]*\.(7z|avi|bz2|flac|flv|gz|mka|mkv|mov|mp3|mp4|mpeg|mpg|ogg|ogm|opus|rar|tar|tgz|tbz|txz|wav|webm|xz|zip)(\?.*)?$") {
    unset req.http.Cookie;
    return (hash);
  }

# Remove all cookies for static files
# A valid discussion could be held on this line: do you really need to cache static files that don't cause load? Only if you have memory left.
# Sure, there's disk I/O, but chances are your OS will already have these files in their buffers (thus memory).
# Before you blindly enable this, have a read here: https://ma.ttias.be/stop-caching-static-files/
  if (req.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|otf|ogg|ogm|opus|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
    unset req.http.Cookie;
    return (hash);
  }

# Normalize Accept-Encoding header (https://www.varnish-cache.org/docs/3.0/tutorial/vary.html)
  if (req.http.Accept-Encoding) {
    if (req.url ~ "(?i)\.(eot|woff|ttf|svg|png|gif|jpeg|jpg|swf|gz|gzip|tgz|bz2|tbz|mp3|ogg|mp4|flv|f4v)(\?.*|)$") {
      unset req.http.Accept-Encoding;
    }
  }

# Don't allow static files to set cookies.
# Commented due to conflict with firewall and backend previews
#if (req.url ~ "(?i)\.(eot|woff|ttf|svg|png|gif|jpeg|jpg|ico|swf|css|js|gz|gzip|tgz|bz2|tbz|mp3|ogg|wep|mp4|flv|f4v|txt)(\?.*|)$")
#{
#    unset req.http.cookie;
#}

#
# Handling the request
# ##########################################################################
# Send Surrogate-Capability headers to announce ESI support to backend
  set req.http.Surrogate-Capability = "key=ESI/1.0";

  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method  != "PATCH" &&
      req.method != "DELETE"
     ) {
    /* Non-RFC2616 or CONNECT which is weird. */
    return (pipe);
  }

# Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
  if (req.http.Upgrade ~ "(?i)websocket") {
    return (pipe);
  }

# Large static files should be piped, so they are delivered directly to the end-user without
# waiting for Varnish to fully read the file first.
# TODO: once the Varnish Streaming branch merges with the master branch, use streaming here to avoid locking.
  if (req.url ~ "^[^?]*\.(bz2|flv|f4v|mp[34]|swf|ogg|rar|tar|tgz|gz|gzip|tar|tbz|tgz|wav|zip)(\?.*)?$") {
    unset req.http.Cookie;
    return (pipe);
  }

# Pass to backend if NOT GET nor HEAD requests
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

# Pass to backend if the request requires Authorization
  if (req.http.Authorization) {
    return (pass);
  }

# Pass requests to backend without queuing them in varnish
  if (req.url ~ "(^/(admin|manager|ws|user)(/$|/.*))" ) {
    return (pass);
  }

# UPDATE 6.2 (https://varnish-cache.org/docs/6.2/whats-new/upgrading-6.2.html#vcl)
  if (req.restarts > 0) {
    set req.hash_always_miss = true;
  }

# By default, fetch from cache
  return (hash);
}

#########
##
## vcl_pipe()
##
## Called upon entering pipe mode.
## In this mode, the request is passed on to the backend, and any further data from both the client
## and backend is passed on unaltered until either end closes the connection. Basically, Varnish will
## degrade into a simple TCP proxy, shuffling bytes back and forth. For a connection in pipe mode,
## no other VCL subroutine will ever get called after vcl_pipe.
##
##########
sub vcl_pipe {
# Note that only the first request to the backend will have
# X-Forwarded-For set.  If you use X-Forwarded-For and want to
# have it set for all requests, make sure to have:
# set bereq.http.connection = "close";
# here.  It is not set by default as it might break some broken web
# applications, like IIS with NTLM authentication.

# set bereq.http.Connection = "Close";

# Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }

  return (pipe);
}

#########
##
## vcl_pass()
##
## Called upon entering pass mode. In this mode, the request is passed on to the backend, and the
## backend's response is passed on to the client, but is not entered into the cache. Subsequent
## requests submitted over the same client connection are handled normally.
##
##########
sub vcl_pass {
# return (pass);
}

#########
##
## vcl_hash()
##
## Defines which request properties are eligible for building a cache hash
## Called after vcl_recv to create a hash value for the request. This is used as a key
## to look up the object in Varnish.
##
##########
sub vcl_hash {
  hash_data(req.url);

  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }

# If the client supports compression, keep that in a different cache
  if (req.http.Accept-Encoding) {
    hash_data(req.http.Accept-Encoding);
  }

# Include the X-Forward-Proto header, since we want to treat HTTPS
# requests differently, and make sure this header is always passed
# properly to the backend server.
  if (req.http.X-Forwarded-Proto) {
    hash_data(req.http.X-Forwarded-Proto);
  }
}

# varnish 4 -> 5: return (fetch) -> return (miss)
# varnish 6.1 -> 6.2: return(miss) removed from vcl_hit{}
# (https://varnish-cache.org/docs/6.2/whats-new/upgrading-6.2.html#vcl)
sub vcl_hit {
# Called when a cache lookup is successful.

  if (obj.ttl >= 0s) {
# A pure unadultered hit, deliver it
    return (deliver);
  }

# https://www.varnish-cache.org/docs/trunk/users-guide/vcl-grace.html
# When several clients are requesting the same page Varnish will send one request to the backend and place the others on hold while fetching one copy from the backend. In some products this is called request coalescing and Varnish does this automatically.
# If you are serving thousands of hits per second the queue of waiting requests can get huge. There are two potential problems - one is a thundering herd problem - suddenly releasing a thousand threads to serve content might send the load sky high. Secondly - nobody likes to wait. To deal with this we can instruct Varnish to keep the objects in cache beyond their TTL and to serve the waiting requests somewhat stale content.

# if (!std.healthy(req.backend_hint) && (obj.ttl + obj.grace > 0s)) {
#   return (deliver);
# } else {
#   return (fetch);
# }

# We have no fresh fish. Lets look at the stale ones.
  if (std.healthy(req.backend_hint)) {
# Backend is healthy. Limit age to 10s.
    if (obj.ttl + 10s > 0s) {
#set req.http.grace = "normal(limited)";
      return (deliver);
    } else {
# No candidate for grace. Fetch a fresh object.
      return (restart);
    }
  } else {
# backend is sick - use full grace
    if (obj.ttl + obj.grace > 0s) {
#set req.http.grace = "full";
      return (deliver);
    } else {
# no graced object.
      return (restart);
    }
  }

# fetch & deliver once we get the result
  return (restart); # Dead code, keep as a safeguard
}

sub vcl_miss {
# Called after a cache lookup if the requested document was not found in the cache. Its purpose
# is to decide whether or not to attempt to retrieve the document from the backend, and which
# backend to use.

  return (fetch);
}

#########
##
## vcl_backend_response()
##
## Fetches resources from backend and handles the cache properties
##
##########
sub vcl_backend_response {

  if (beresp.status >= 500 && beresp.status < 505) {
     if (beresp.http.Content-Type != "application/json") {
       return(abandon);
     }
     unset beresp.http.set-cookie;
  }

#
# Response modification
# ##########################################################################
# unset beresp.http.Cache-Control;

# Pause ESI request and remove Surrogate-Control header
  if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
    unset beresp.http.Surrogate-Control;
    set beresp.do_esi = true;
  }

# Enable cache for all static files
# The same argument as the static caches from above: monitor your cache size, if you get data nuked out of it, consider giving up the static file cache.
# Before you blindly enable this, have a read here: https://ma.ttias.be/stop-caching-static-files/
  if (bereq.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|otf|ogg|ogm|opus|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
    unset beresp.http.set-cookie;
  }

# Large static files are delivered directly to the end-user without
# waiting for Varnish to fully read the file first.
# Varnish 4 fully supports Streaming, so use streaming here to avoid locking.
  if (bereq.url ~ "^[^?]*\.(7z|avi|bz2|flac|flv|gz|mka|mkv|mov|mp3|mp4|mpeg|mpg|ogg|ogm|opus|rar|tar|tgz|tbz|txz|wav|webm|xz|zip)(\?.*)?$") {
    unset beresp.http.set-cookie;
    set beresp.do_stream = true;  # Check memory usage it'll grow in fetch_chunksize blocks (128k by default) if the backend doesn't send a Content-Length header, so only enable it for big objects
      set beresp.do_gzip = false;   # Don't try to compress it for storage
  }

# If the response is text based allow to gzip it
  if (beresp.http.content-type ~ "text") {
    set beresp.do_gzip = true;
  }

  if (beresp.http.Vary ~ "User-Agent") {
    set beresp.http.Vary = regsub(bereq.http.Cookie, "(^|; )*User-Agent,? *", "\1");
    if (beresp.http.Vary == "") {
      unset beresp.http.Vary;
    }
  }

#
# Pass through some request to backend, right away
# ##########################################################################

# Pass requests to backend without queuing them in varnish
  if (bereq.url ~ "^(/(admin|manager|ws|user)(/$|/.*))" ) {
    set beresp.uncacheable = true;
    set beresp.ttl = 0s;
    return (deliver);
  }

#
# Rules for caching - the MOJO part!!
# ##########################################################################

  set beresp.ttl   = 0s;
  set beresp.grace = 0s;

# If the request has the x-tags header then it could be cacheable
  if (beresp.status < 299 && beresp.http.x-tags) {
    if (beresp.http.x-cache-for) {
      set beresp.ttl   = std.duration(beresp.http.x-cache-for, 0s);
      set beresp.grace = std.duration(beresp.http.x-cache-for, 0s);
    } else {
      set beresp.ttl   = 6h;
      set beresp.grace = 6h;
    }

#Remove Expires from backend, it's not long enough
    unset beresp.http.expires;
    set beresp.http.Cache-Control = "max-age=30";
  }

# Static files treatment
  if ( beresp.status < 299 && (beresp.http.content-type ~ "image|font" || bereq.url ~ "(?i)\.(eot|woff|woff2|ttf|svg|png|gif|jpeg|jpg|ico|swf|css|js|gz|gzip|tgz|bz2|tbz|txt)(\?.*|)$" )) {
# unset beresp.http.set-cookie;
    set beresp.ttl = 15d;
    set beresp.grace = 15d;

    set beresp.do_gzip = true;

#Remove Expires from backend, it's not long enough
    unset beresp.http.expires;
    set beresp.http.Cache-Control = "max-age=1296000";
  }

# Cache for 10s 404 errors
  if (beresp.status == 404) {
    set beresp.ttl = 6h;
  }

# Cache for 10s 500 errors
  if (beresp.status >= 500) {
    set beresp.ttl = 10s;
  }

#set beresp.ttl = 10d; # Use this to test if cache works. Sets all to be cacheable

  if (beresp.ttl <= 0s) { # Varnish determined the object was not cacheable
    set beresp.http.X-Cacheable = "NO:Not Cacheable";
    set beresp.uncacheable = true;
  } elsif (beresp.http.Cache-Control ~ "private") { # You are respecting the Cache-Control=private header from the backend
    set beresp.http.X-Cacheable = "NO:Cache-Control=private";
    set beresp.uncacheable = true;
    return (deliver);
  } else { # Varnish determined the object was cacheable
    set beresp.http.X-Cacheable = "YES";
    if (beresp.http.Set-Cookie) {
      unset beresp.http.Set-Cookie;
    }
  }

# Set headers to allow cache invalidation
  set beresp.http.x-url  = bereq.url;
  set beresp.http.x-host = bereq.http.host;
  set beresp.http.X-ttl = beresp.ttl;

  # Sometimes, a 301 or 302 redirect formed via Apache's mod_rewrite can mess with the HTTP port that is being passed along.
  # This often happens with simple rewrite rules in a scenario where Varnish runs on :80 and Apache on :8080 on the same box.
  # A redirect can then often redirect the end-user to a URL on :8080, where it should be :80.
  # This may need finetuning on your setup.
  #
  # To prevent accidental replace, we only filter the 301/302 redirects for now.
  if (beresp.status == 301 || beresp.status == 302) {
    set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
  }

  # Allow stale content, in case the backend goes down.
  # make Varnish keep all objects for 6 hours beyond their TTL
  set beresp.grace = 6h;

  return (deliver);
}

#########
#
# vcl_deliver()
#
# Sends the response to the client adding some ONM-specific parameters
#
#########
sub vcl_deliver {
#
# Identify requests served from cache
# ##########################################################################
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }

# Please note that obj.hits behaviour changed in 4.0, now it counts per objecthead, not per object
# and obj.hits may not be reset in some cases where bans are in use. See bug 1492 for details.
# So take hits with a grain of salt
  set resp.http.X-Cache-Hits = obj.hits;

#
# Removing unuseful/development headers
# ##########################################################################
# Avoid to send cache related headers to client
  unset resp.http.x-url;
  unset resp.http.x-host;

# Remove some headers
  unset resp.http.Server;
  unset resp.http.X-Mod-Pagespeed;

# uncomment this in production
  unset resp.http.X-Varnish;
  unset resp.http.X-ttl;
  unset resp.http.x-tags;
  unset resp.http.X-Cacheable;
  unset resp.http.x-instance;
  unset resp.http.x-cache-for;
  unset resp.http.X-Cache-Hits;

  unset resp.http.Expires;
  unset resp.http.Etag;
#  unset resp.http.Last-Modified;
  unset resp.http.Pragma;

#
# Adding some headers from our service
# ##########################################################################
  set resp.http.X-Powered-By = "OpenNemas";
  set resp.http.Via = "Opennemas Proxy Server";

#
# Returning the response
# ##########################################################################
  return (deliver);
}


#########
#
# vcl_synth()
#
# Handles all the errors during the process
#
#########
sub vcl_synth {
  if (req.method == "BAN") {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    synthetic({""} + resp.reason + {""});
  } elseif (resp.status == 720) {
# We use this special error status 720 to force redirects with 301 (permanent) redirects
# To use this, call the following from anywhere in vcl_recv: return (synth(720, "http://host/new.html"));
    set resp.http.Location = resp.reason;
    set resp.status = 301;
    return (deliver);
  } elseif (resp.status == 721) {
# And we use error status 721 to force redirects with a 302 (temporary) redirect
# To use this, call the following from anywhere in vcl_recv: return (synth(720, "http://host/new.html"));
    set resp.http.Location = resp.reason;
    set resp.status = 302;
    return (deliver);
  } elseif (resp.status >= 500 && resp.status < 505) {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    synthetic(std.fileread("/etc/varnish/conf.d/error.html"));
  }

  return (deliver);
}

sub vcl_backend_error {
  set beresp.http.Content-Type = "text/html; charset=utf-8";
  set beresp.http.Retry-After = "5";
  synthetic(std.fileread("/etc/varnish/conf.d/error.html"));
  return (deliver);
}

sub vcl_fini {
# Called when VCL is discarded only after all requests have exited the VCL.
# Typically used to clean up VMODs.

  return (ok);
}
