when HTTP_REQUEST {
   HTTP::respond 200 content {
      <html>
         <head>
            <title>BIG-IP</title>
         </head>
         <body>
            200 OK
         </body>
      </html>
   }
}