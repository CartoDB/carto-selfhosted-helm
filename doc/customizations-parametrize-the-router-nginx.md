### Parametrize Router Nginx

Carto Router uses Nginx to manage the requests inside the namespace. These are the parameters you can update for your installation:

  > ref: https://nginx.org/en/docs/dirindex.html

  | Parameter | Description |
  |---|---|
  | `gzip_buffers` | Sets the number and size of buffers used to compress a response |
  | `gzip_min_length` | Sets the minimum length of a response that will be gzipped |
  | `proxy_buffers` | Sets the number and size of the buffers used for reading a response from the proxied server, for a single connection |
  | `proxy_buffer_size` | Sets the size of the buffer used for reading the first part of the response received from the proxied server |
  | `proxy_busy_buffers_size` | Limits the total size of buffers that can be busy sending a response to the client while the response is not yet fully read |
  | `client_max_body_size` | Sets the maximum allowed size of the client request body |

  Default values for these parameters are:

  ```bash
  gzip_buffers: "16 8k"
  gzip_min_length: "1100"
  proxy_buffers: "16 32k"
  proxy_buffer_size: "32k"
  proxy_busy_buffers_size: "64k"
  client_max_body_size: "10M"
  ```

  You can override any of them in your customizations file, e.g:

  ```diff
  router:
    nginxConfig:
+      client_max_body_size: "20M"
  ```