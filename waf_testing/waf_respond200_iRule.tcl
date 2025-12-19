when HTTP_REQUEST {
    # Capture the full URI and method
    set method [HTTP::method]
    set uri [HTTP::uri]
    set host [HTTP::host]
    set path [HTTP::path]
    set query [HTTP::query]
    
    # Get all HTTP headers
    set header_names [HTTP::header names]
    
    # Check if client is curl or similar CLI tool
    set user_agent [HTTP::header "User-Agent"]
    set is_cli 0
    if { [expr {[string match -nocase "*curl*" $user_agent] || [string match -nocase "*wget*" $user_agent] || [string match -nocase "*httpie*" $user_agent]}] } {
        set is_cli 1
    }
    
    if { $is_cli } {
        # Build text-based response for CLI clients
        set output "===============================================================\n"
        append output "               HTTP REQUEST INFORMATION                    \n"
        append output "===============================================================\n\n"
        
        append output "FULL URL\n"
        append output "---------------------------------------------------------------\n"
        append output "  http://$host$uri\n\n"
        
        append output "URL COMPONENTS\n"
        append output "---------------------------------------------------------------\n"
        append output "  Method:       $method\n"
        append output "  Host:         $host\n"
        append output "  Path:         $path\n"
        append output "  Query String: $query\n\n"
        
        append output "QUERY PARAMETERS\n"
        append output "---------------------------------------------------------------\n"
        if { $query ne "" } {
            foreach param [split $query "&"] {
                set param_parts [split $param "="]
                set param_name [lindex $param_parts 0]
                set param_value [lindex $param_parts 1]
                set param_value [URI::decode $param_value]
                append output "  [format "%-20s" $param_name] = $param_value\n"
            }
        } else {
            append output "  (No query parameters)\n"
        }
        
        append output "\nCOOKIES\n"
        append output "---------------------------------------------------------------\n"
        set cookie_header [HTTP::cookie names]
        if { [llength $cookie_header] > 0 } {
            foreach cookie_name $cookie_header {
                set cookie_value [HTTP::cookie value $cookie_name]
                append output "  [format "%-20s" $cookie_name] = $cookie_value\n"
            }
        } else {
            append output "  (No cookies)\n"
        }
        
        append output "\nHTTP HEADERS\n"
        append output "---------------------------------------------------------------\n"
        if { [llength $header_names] > 0 } {
            foreach header_name $header_names {
                set header_value [HTTP::header value $header_name]
                append output "  [format "%-20s" $header_name] = $header_value\n"
            }
        } else {
            append output "  (No headers)\n"
        }
        
        append output "\n===============================================================\n"
        
        HTTP::respond 200 content $output "Content-Type" "text/plain; charset=utf-8"
        
    } else {
        # Parse query parameters for HTML
        set query_params ""
        if { $query ne "" } {
            foreach param [split $query "&"] {
                set param_parts [split $param "="]
                set param_name [lindex $param_parts 0]
                set param_value [lindex $param_parts 1]
                set param_value [URI::decode $param_value]
                append query_params "<tr><td style='padding: 8px; border: 1px solid #ddd;'>$param_name</td><td style='padding: 8px; border: 1px solid #ddd;'>$param_value</td></tr>"
            }
        } else {
            set query_params "<tr><td colspan='2' style='padding: 8px; border: 1px solid #ddd; text-align: center; color: #999;'>No query parameters</td></tr>"
        }
        
        # Parse cookies for HTML
        set cookie_header [HTTP::cookie names]
        set cookies ""
        if { [llength $cookie_header] > 0 } {
            foreach cookie_name $cookie_header {
                set cookie_value [HTTP::cookie value $cookie_name]
                append cookies "<tr><td style='padding: 8px; border: 1px solid #ddd;'>$cookie_name</td><td style='padding: 8px; border: 1px solid #ddd;'>$cookie_value</td></tr>"
            }
        } else {
            set cookies "<tr><td colspan='2' style='padding: 8px; border: 1px solid #ddd; text-align: center; color: #999;'>No cookies</td></tr>"
        }
        
        # Parse headers for HTML
        set headers ""
        if { [llength $header_names] > 0 } {
            foreach header_name $header_names {
                set header_value [HTTP::header value $header_name]
                # Escape HTML special characters
                regsub -all {<} $header_value {\&lt;} header_value
                regsub -all {>} $header_value {\&gt;} header_value
                append headers "<tr><td style='padding: 8px; border: 1px solid #ddd;'>$header_name</td><td style='padding: 8px; border: 1px solid #ddd;'>$header_value</td></tr>"
            }
        } else {
            set headers "<tr><td colspan='2' style='padding: 8px; border: 1px solid #ddd; text-align: center; color: #999;'>No headers</td></tr>"
        }
        
        # Build HTML response for browsers
        set html "<!DOCTYPE html>
<html>
<head>
    <title>Request Information</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; background-color: white; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #e21d38; color: white; padding: 12px; text-align: left; border: 1px solid #ddd; }
        td { padding: 8px; border: 1px solid #ddd; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .info-box { background-color: white; padding: 15px; margin-bottom: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <h1>HTTP Request Information</h1>
    
    <div class='info-box'>
        <strong>Full URL:</strong> http://$host$uri
    </div>
    
    <h2>URL Components</h2>
    <table>
        <tr><th>Component</th><th>Value</th></tr>
        <tr><td style='padding: 8px; border: 1px solid #ddd;'>Method</td><td style='padding: 8px; border: 1px solid #ddd;'>$method</td></tr>
        <tr><td style='padding: 8px; border: 1px solid #ddd;'>Host</td><td style='padding: 8px; border: 1px solid #ddd;'>$host</td></tr>
        <tr><td style='padding: 8px; border: 1px solid #ddd;'>Path</td><td style='padding: 8px; border: 1px solid #ddd;'>$path</td></tr>
        <tr><td style='padding: 8px; border: 1px solid #ddd;'>Query String</td><td style='padding: 8px; border: 1px solid #ddd;'>$query</td></tr>
    </table>
    
    <h2>Query Parameters</h2>
    <table>
        <tr><th>Parameter</th><th>Value</th></tr>
        $query_params
    </table>
    
    <h2>Cookies</h2>
    <table>
        <tr><th>Cookie Name</th><th>Cookie Value</th></tr>
        $cookies
    </table>
    
    <h2>HTTP Headers</h2>
    <table>
        <tr><th>Header Name</th><th>Header Value</th></tr>
        $headers
    </table>
</body>
</html>"
        
        HTTP::respond 200 content $html "Content-Type" "text/html"
    }
}
