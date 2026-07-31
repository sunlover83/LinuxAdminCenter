#!/usr/bin/env bash

get_active_network_interfaces() {
    local interfaces=""

    if ! command -v ip >/dev/null 2>&1; then
        printf '%s\n' "unknown"
        return
    fi

    interfaces="$(
        LC_ALL=C ip -o link show up 2>/dev/null |
            awk -F ': ' '
                {
                    name = $2
                    sub(/@.*/, "", name)

                    if (name != "" && name != "lo" && !seen[name]++) {
                        if (result != "") {
                            result = result "; "
                        }

                        result = result name
                    }
                }

                END {
                    if (result != "") {
                        print result
                    }
                }
            '
    )"

    if [[ -n "$interfaces" ]]; then
        printf '%s\n' "$interfaces"
    else
        printf '%s\n' "none"
    fi
}

get_ipv4_addresses() {
    local addresses=""

    if ! command -v ip >/dev/null 2>&1; then
        printf '%s\n' "unknown"
        return
    fi

    addresses="$(
        LC_ALL=C ip -o -4 addr show scope global 2>/dev/null |
            awk '
                {
                    interface_name = $2
                    address = $4

                    sub(/@.*/, "", interface_name)

                    entry = interface_name ": " address

                    if (interface_name != "" && address != "" && !seen[entry]++) {
                        if (result != "") {
                            result = result "; "
                        }

                        result = result entry
                    }
                }

                END {
                    if (result != "") {
                        print result
                    }
                }
            '
    )"

    if [[ -n "$addresses" ]]; then
        printf '%s\n' "$addresses"
    else
        printf '%s\n' "none"
    fi
}

get_default_gateway() {
    local gateway=""

    if ! command -v ip >/dev/null 2>&1; then
        printf '%s\n' "unknown"
        return
    fi

    gateway="$(
        LC_ALL=C ip -4 route show default 2>/dev/null |
            awk '
                /^default/ {
                    gateway_address = ""
                    interface_name = ""

                    for (i = 1; i <= NF; i++) {
                        if ($i == "via" && i < NF) {
                            gateway_address = $(i + 1)
                        }

                        if ($i == "dev" && i < NF) {
                            interface_name = $(i + 1)
                        }
                    }

                    if (gateway_address != "" && interface_name != "") {
                        print gateway_address " via " interface_name
                    } else if (gateway_address != "") {
                        print gateway_address
                    } else if (interface_name != "") {
                        print "via " interface_name
                    }

                    exit
                }
            '
    )"

    if [[ -n "$gateway" ]]; then
        printf '%s\n' "$gateway"
    else
        printf '%s\n' "none"
    fi
}

get_dns_servers() {
    local dns_servers=""
    local resolv_conf

    if command -v resolvectl >/dev/null 2>&1; then
        dns_servers="$(
            LC_ALL=C resolvectl dns 2>/dev/null |
                awk -F ': ' '
                    NF >= 2 {
                        entry_count = split($2, entries, /[[:space:]]+/)

                        for (i = 1; i <= entry_count; i++) {
                            value = entries[i]
                            sub(/%.*/, "", value)

                            if (value != "" && !seen[value]++) {
                                if (result != "") {
                                    result = result "; "
                                }

                                result = result value
                            }
                        }
                    }

                    END {
                        if (result != "") {
                            print result
                        }
                    }
                '
        )"
    fi

    if [[ -z "$dns_servers" ]]; then
        for resolv_conf in \
            /run/systemd/resolve/resolv.conf \
            /etc/resolv.conf; do

            [[ -r "$resolv_conf" ]] || continue

            dns_servers="$(
                awk '
                    $1 == "nameserver" && $2 != "" {
                        value = $2
                        sub(/%.*/, "", value)

                        if (!seen[value]++) {
                            if (result != "") {
                                result = result "; "
                            }

                            result = result value
                        }
                    }

                    END {
                        if (result != "") {
                            print result
                        }
                    }
                ' "$resolv_conf"
            )"

            [[ -n "$dns_servers" ]] && break
        done
    fi

    if [[ -n "$dns_servers" ]]; then
        printf '%s\n' "$dns_servers"
    else
        printf '%s\n' "unknown"
    fi
}
