# Smart Proxy - Onboard

[![Gem Version](https://badge.fury.io/rb/smart_proxy_onboard.svg)](https://badge.fury.io/rb/smart_proxy_onboard)
[![Build Status](https://travis-ci.org/Deltik/smart_proxy_onboard.svg?branch=develop)](https://travis-ci.org/Deltik/smart_proxy_onboard)
[![Code Climate](https://codeclimate.com/github/Deltik/smart_proxy_onboard/badges/gpa.svg)](https://codeclimate.com/github/Deltik/smart_proxy_onboard)

The **Smart Proxy Onboard Plugin** (**`smart_proxy_onboard`**) exposes useful API methods for the earliest part of the server lifecycle management process: onboarding new servers into [Foreman](https://github.com/theforeman/foreman).

This plugin is used for the onboarding process before server discovery.  It plugs into [Smart Proxy](https://github.com/theforeman/smart-proxy) to cover the same network ranges as the Smart Proxy.

[Rails DCIM Portal](https://github.com/buddwm/Rails_DCIM_Portal) uses the API methods in this plugin to scan a range of IP addresses to see which ones respond to IPMI.  Rails DCIM Portal then iterates over the list, finding IPMI credentials that work for each IP address.  These IPMI hosts are then considered scanned and can subsequently be discovered into Foreman by PXE booting into the discovery image from [`foreman_discovery`](https://github.com/theforeman/foreman_discovery).  Finally, while Foreman provisions the discovered hosts, Rails DCIM Portal can write inventory facts into the provisioned hosts to complete the onboarding process.

## Installation

Follow the ["Advanced Installation from Gems" instructions in the Foreman plugins documentation](https://theforeman.org/plugins/#2.3AdvancedInstallationfromGems) to install this plugin.

The gem name is `smart_proxy_onboard`.

## Configuration

All configurable options for this plugin are documented at [settings.d/onboard.yml.example](settings.d/onboard.yml.example) and should be copied to `/etc/foreman-proxy/settings.d/onboard.yml`.

## Compatible Software

This plugin is made for the following combination of software:

 - [**Rails DCIM Portal**](https://github.com/buddwm/Rails_DCIM_Portal)
 - [**Smart Proxy**](https://github.com/theforeman/smart-proxy) (>= 1.16)
 - [**Foreman - Discovery**](https://github.com/theforeman/foreman_discovery)
 - [**Smart Proxy - Discovery**](https://github.com/theforeman/smart_proxy_discovery)

## Features

### Currently Implemented

 - IPMI IP range scanner

### Planned

No additional features have been planned so far.

## API

### `GET /onboard/bmc/scan`

Shows available resources `/onboard/bmc/scan/range` and `/onboard/bmc/scan/cidr`

    {
      "available_resources": [
        "range",
        "cidr"
      ]
    }

### `GET /onboard/bmc/scan/range`

Shows usage on specifying a beginning IP address and an ending IP address for making a scan request

    {
      "message": "You need to supply a range with /onboard/bmc/scan/range/:address_first/:address_last"
    }

### `GET /onboard/bmc/scan/cidr`

Shows usage on specifying an IP address and its netmask in dot decimal format or prefixlen format for making a scan request

    {
      "message": "You need to supply a CIDR with /onboard/bmc/scan/cidr/:address/:netmask (e.g. \"192.168.1.1/24\" or \"192.168.1.1/255.255.255.0\")"
    }

### `GET /onboard/bmc/scan/range/:address_first/:address_last`

Performs an IPMI ping scan from `:address_first` to `:address_last` and returns the result in key "`result`" of a JSON hash

Sample output for `/onboard/bmc/scan/range/10.246.0.65/10.246.0.71`:

    {
      "result": [
        "10.246.0.65",
        "10.246.0.69",
        "10.246.0.70",
        "10.246.0.66",
        "10.246.0.68",
        "10.246.0.71",
        "10.246.0.67"
      ]
    }

### `GET /onboard/bmc/scan/cidr/:address/:netmask`

Performs an IPMI ping scan in the CIDR range of `:address`/`:netmask`, where `:netmask` is in decimal format (e.g. "`255.255.255.0`") or in prefixlen format (e.g. "`24`")

Sample output for `/onboard/bmc/scan/cidr/10.246.0.65/29`:

    {
      "result": [
        "10.246.0.69",
        "10.246.0.70",
        "10.246.0.65",
        "10.246.0.66",
        "10.246.0.67",
        "10.246.0.68",
        "10.246.0.71"
      ]
    }

### `DELETE /onboard/bmc/sdr_cache`

(_FreeIPMI only_) Deletes the sensor data repository (SDR) cache from the Smart Proxy.
