# Ansible managed file
set obj.http.Content-Type = "text/html; charset=utf-8";
set obj.http.Retry-After = "5";
synthetic std.fileread("/etc/varnish/conf.d/error.html");
