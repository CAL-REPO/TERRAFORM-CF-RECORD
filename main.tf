terraform {
    required_version = ">= 1.0"
    required_providers {
        cloudflare = {
            source  = "cloudflare/cloudflare"
            version = "~> 4.0"
        }
    }
}

data "cloudflare_zone" "ZONE" {
    count = (length("${var.RECORDs}") > 0 ?
            length("${var.RECORDs}") : 0)
    name = "${var.RECORDs[count.index].DOMAIN}"
}

resource "cloudflare_record" "ADD_RECORD" {
    count = (length("${var.RECORDs}") > 0 ?
            length("${var.RECORDs}") : 0)

    zone_id = "${data.cloudflare_zone.ZONE[count.index].id}"
    name    = "${var.RECORDs[count.index].NAME}"
    type    = "${var.RECORDs[count.index].TYPE}"
    value   = "${var.RECORDs[count.index].VALUE}"
    ttl     = "${var.RECORDs[count.index].TTL}"
}

resource "null_resource" "WAIT_RECORD_STATUS" {
    count = (length("${var.RECORDs}") > 0 ?
            length("${var.RECORDs}") : 0)    
    depends_on = [ cloudflare_record.ADD_RECORD ]

    provisioner "local-exec" {
        command = <<-EOF
        EXPECTED_RECORD="${var.RECORDs[count.index].VALUE}"

        while : ; do
            REGISTERED_RECORD="$(dig +short "${var.RECORDs[count.index].NAME}.${var.RECORDs[count.index].DOMAIN}" "${var.RECORDs[count.index].TYPE}")"
            EXPECTED_RECORD_EXISTS=true

            if [[ "$REGISTERED_RECORD" != *"$EXPECTED_RECORD"* ]]; then
                EXPECTED_RECORD_EXISTS=false
                break
            fi

            if $EXPECTED_RECORD_EXISTS = true; then
                echo "Record is activated"
                break
            else
                echo "Record is not activated yet"
                sleep 5
            fi
        done
        EOF
        interpreter = ["bash", "-c"]
    }
}

