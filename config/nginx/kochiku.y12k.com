server {
       listen         80;
       server_name kochiku.y12k.com localhost;
       rewrite        ^ https://$server_name$request_uri? permanent;
}

server {
        server_name kochiku.y12k.com localhost;
        listen 443;

        root /app/ubuntu/kochiku/current/public;
	rails_env production;
        passenger_enabled on;

	location ~* ^/assets/ {
	    expires 1y;
	    add_header Cache-Control public;

	    add_header Last-Modified "";
	    add_header ETag "";
	    break;
	}

        ssl on;
        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key; 

	auth_basic "Restricted";
	auth_basic_user_file /etc/nginx/ssl/.htpasswd;
}
