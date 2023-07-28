variable "RECORDs" {
    type = list(object({
        DOMAIN = string
        NAME = string
        TYPE = string
        VALUE = string
        TTL = string
    }))
    
    default = []
}