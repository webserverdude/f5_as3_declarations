when CLIENTSSL_CLIENTHELLO priority 100 {
  if {[SSL::extensions exists -type 0]} {
    binary scan [SSL::extensions -type 0] @9a* SNI
    if {[regexp {(?i)[^a-z0-9.-]} $SNI]} {
      log local0. "CLIENTSSL_CLIENTHELLO client offered bogus SNI: $SNI"
    } else {
      virtual [class match -value -- [string tolower $SNI] equals /sni_routing/app_sni_routing/datagroup_sni_routing]
      return
    }
  }
}