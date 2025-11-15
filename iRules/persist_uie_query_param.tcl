when RULE_INIT {
    # enable (1) / disable (0) logging
    set static::irule_debug 0
}

when HTTP_REQUEST {
    set pin_value [URI::query [HTTP::uri] pin]
    if { $pin_value ne "" } {
        set pin_value [URI::decode $pin_value]
        persist uie $pin_value
    }
    if { $static::irule_debug } {
        log local0. "Universal Persist iRule: HTTP_REQUEST event fired, pin_value=$pin_value"
    }
}

when HTTP_RESPONSE {
    if { $static::irule_debug } {
        log local0. "Universal Persist iRule: HTTP_RESPONSE event fired, pin_value=$pin_value"
    }
    persist add uie $pin_value
}