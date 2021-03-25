# Ansible managed file
backend app02fra1doc {
  .host = "app02fra1doc.pre.opennemas.net";
  .port = "8080";
  .connect_timeout = 25s;
  .first_byte_timeout = 30s;
  .between_bytes_timeout = 25s;
  .max_connections = 5000;
  .probe = { .url = "/favicon.ico"; .interval = 3s; .timeout = 2s; .window = 5;.threshold = 3; }
}
backend app03fra1doc {
  .host = "app03fra1doc.pre.opennemas.net";
  .port = "8080";
  .connect_timeout = 25s;
  .first_byte_timeout = 30s;
  .between_bytes_timeout = 25s;
  .max_connections = 5000;
  .probe = { .url = "/favicon.ico"; .interval = 3s; .timeout = 2s; .window = 5;.threshold = 3; }
}
