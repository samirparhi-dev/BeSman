#!/usr/bin/env bash

#
#   Copyright 2020 the original author or authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function ___besman_check_candidates_cache() {
	local candidates_cache="$1"
	if [[ -f "$candidates_cache" && -n "$(< "$candidates_cache")" && -n "$(find "$candidates_cache" -mmin +$((24 * 60 * 30)))" ]]; then
		__besman_echo_yellow 'We periodically need to update the local cache. Please run:'
		echo ''
		__besman_echo_no_colour '  $ bes update'
		echo ''
		return 0
	elif [[ -f "$candidates_cache" && -z "$(< "$candidates_cache")" ]]; then
		__besman_echo_red 'WARNING: Cache is corrupt. BESMAN cannot be used until updated.'
		echo ''
		__besman_echo_no_colour '  $ bes update'
		echo ''
		return 1
	else
		__besman_echo_debug "No update at this time. Using existing cache: $BESMAN_CANDIDATES_CSV"
		return 0
	fi
}

function ___besman_check_version_cache() {
	local version_url
	local version_file="${BESMAN_DIR}/var/version"

	if [[ "$besman_beta_channel" != "true" && -f "$version_file" && -z "$(find "$version_file" -mmin +$((60 * 24)))" ]]; then
		__besman_echo_debug "Not refreshing version cache now..."
		BESMAN_REMOTE_VERSION=$(cat "$version_file")
	else
		__besman_echo_debug "Version cache needs updating..."
		if [[ "$besman_beta_channel" == "true" ]]; then
			__besman_echo_debug "Refreshing version cache with BETA version."
			version_url="${BESMAN_CANDIDATES_API}/broker/download/besman/version/beta"
		else
			__besman_echo_debug "Refreshing version cache with STABLE version."
			version_url="${BESMAN_CANDIDATES_API}/broker/download/besman/version/stable"
		fi

		BESMAN_REMOTE_VERSION=$(__besman_secure_curl_with_timeouts "$version_url")
		if [[ -z "$BESMAN_REMOTE_VERSION" || -n "$(echo "$BESMAN_REMOTE_VERSION" | tr '[:upper:]' '[:lower:]' | grep 'html')" ]]; then
			__besman_echo_debug "Version information corrupt or empty! Ignoring: $BESMAN_REMOTE_VERSION"
			BESMAN_REMOTE_VERSION="$BESMAN_VERSION"
		else
			__besman_echo_debug "Overwriting version cache with: $BESMAN_REMOTE_VERSION"
			echo "${BESMAN_REMOTE_VERSION}" | tee "$version_file" > /dev/null
		fi
	fi
}
