#!/bin/bash

# Blank portainer templates
json_arm32v2='{"version":"2","templates":[]}'
json_arm64v2='{"version":"2","templates":[]}'
json_amd64v2='{"version":"2","templates":[]}'

json_arm32v3='{"version":"3","templates":[]}'
json_arm64v3='{"version":"3","templates":[]}'
json_amd64v3='{"version":"3","templates":[]}'

# File variables
appinfo='build/info.json'
Oldtemplate_arm32v2='pi-hosted_template/template/portainer-v2.json'
template_arm32v2='template/portainer-v2-arm32.json'
template_arm64v2='template/portainer-v2-arm64.json'
template_amd64v2='template/portainer-v2-amd64.json'
template_arm32v3='template/portainer-v3-arm32.json'
template_arm64v3='template/portainer-v3-arm64.json'
template_amd64v3='template/portainer-v3-amd64.json'

# App info
repo='https://github.com/pi-hosted/pi-hosted/blob/master/'
rawrepo='https://raw.githubusercontent.com/pi-hosted/pi-hosted/master/'
header='<b>Template created by Pi-Hosted Series</b><br><b>Check our Github page: <a href="https://github.com/pi-hosted/pi-hosted" target="_blank">https://github.com/pi-hosted/pi-hosted</a></b><br>'

# Run script from base directory
scriptDir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$scriptDir/.." || { echo "Faild to change directory."; exit 1; }

# Initialize the ID counter for v3
id_counter=1

# Parsing all json files in apps folder
for app in template/apps/*.json; do
	# Check if the app file exists and is not empty
 	if [[ -s "$app" ]]; then
  		echo "Processing $app..."
    
		# Adding app template to 32 and 64 bits variables
		appjson=$(jq -e '.' < "$app" 2>/dev/null)
		appjson_v3=$(jq -e '.' < "$app" 2>/dev/null)
  
		if [[ $? -ne 0 ]]; then
			echo "Invalid JSON in $app. Skipping..."
			continue
		fi

		# Add the sequential "id" for v3
    		appjson_v3=$(jq --argjson id "$id_counter" '. + {id: $id}' <<< "$appjson")
    		((id_counter++))

   		# Improve Notes
		note=$( echo "$appjson" | jq '.note' )
		note=$( echo "$appjson_v3" | jq '.note' )
		# Clean Notes
		[ "$note" == "null" ] && unset note
			note=${note:1: -1}
   
		# Official Webpage
		if oweb=$( echo "$appjson" | jq -e '.webpage' ) ; then
			oweb="<br><b>Official Webpage: </b><a href=\"${oweb:1:-1}\" target=\"_blank\">${oweb:1:-1}</a>"
			appjson=$( echo "$appjson" | jq 'del(.webpage)' )
			appjson_V3=$( echo "$appjson_v3" | jq 'del(.webpage)' )
		else
			unset oweb
		fi

		# Official Documentation
		if odoc=$( echo "$appjson" | jq -e '.officialDoc' ) ; then
			odoc="<br><b>Official Docker Documentation: </b><a href=\"${odoc:1:-1}\" target=\"_blank\">${odoc:1:-1}</a>"
			appjson=$( echo "$appjson" | jq 'del(.officialDoc)' )
			appjson_V3=$( echo "$appjson_v3" | jq 'del(.officialDoc)' )
		else
			unset odoc
		fi

		# Pi-Hosted Documentation
		if PHDoc=$( echo "$appjson" | jq -e '.piHostedDoc' ) ; then
			PHDoc="<br><h3><b>Pi-Hosted dedicated documentation: </b><a href=\"${repo}docs/${PHDoc:1:-1}\" target=\"_blank\">${PHDoc:1:-1}</a></h3>"
			appjson=$( echo "$appjson" | jq 'del(.piHostedDoc)' )
			appjson_V3=$( echo "$appjson_v3" | jq 'del(.piHostedDoc)' )
		else
			unset PHDoc
		fi

		# Pre-Install Script
		if Script=$( echo "$appjson" | jq -e '.preInstallScript' ) ; then
			scriptexec=$( jq '.tools[] | select(.File=='"$Script"') | .Exec' "$appinfo" )
			[ "$scriptexec" == "" ] && scriptexec="-bash-"
			Script="<br><h3><b><a href=\"${repo}tools/${Script:1:-1}\" target=\"_blank\">Pre-installation script</a> must be RAN before you install: </b>wget -qO- ${rawrepo}tools/${Script:1:-1} | ${scriptexec:1:-1}</h3>"
			appjson=$( echo "$appjson" | jq 'del(.preInstallScript)' )
			appjson_V3=$( echo "$appjson_v3" | jq 'del(.preInstallScript)' )
		else
			unset Script
		fi

		# Youtube Video
		if vidlist=$( echo "$appjson" | jq -e '.videoID' ) ; then
			appjson=$( echo "$appjson" | jq 'del(.videoID)' )
			appjson_v3=$( echo "$appjson_v3" | jq 'del(.videoID)' )
			# If only one entry
			if [ "$(echo "$vidlist" | wc -l )" == "1" ]; then
				vidInfo=$(jq ".youtube[] | select(.ID==$vidlist)" "$appinfo")
				vidURL=$(echo "$vidInfo" | jq ".URL" | tr -d '"')
				vidTitle=$(echo "$vidInfo" | jq ".Title" | tr -d '"')
				vidCh=$(echo "$vidInfo" | jq ".Channel")
				vidCh=$(jq ".channels[] | select(.ID==$vidCh) | .Title" "$appinfo" | tr -d '"')
				VideoURL="<br><b>Youtube Video: </b><a href=$vidURL target=\"_blank\">$vidCh - $vidTitle</a><br>"

			# If multiple entries
			else
				n_vid=$(echo "$vidlist" | jq '. | length')
				for n in $(seq 0 $(( n_vid - 1 ))); do
					vidd=$(echo "$vidlist" | jq ".[$n]" )
					vidInfo=$(jq ".youtube[] | select(.ID==$vidd)" "$appinfo")
					vidURL=$(echo "$vidInfo" | jq ".URL" | tr -d '"')
					vidTitle=$(echo "$vidInfo" | jq ".Title" | tr -d '"')
					vidCh=$(echo "$vidInfo" | jq ".Channel")
					vidCh=$(jq ".channels[] | select(.ID==$vidCh) | .Title" "$appinfo" | tr -d '"')
					if [ "$n" == "0" ] ; then
						VideoURL="<br><b>Youtube Videos:</b><br><ul><li><a href=$vidURL target=\"_blank\">$vidCh - $vidTitle</a></li>"
					else
						VideoURL="$VideoURL<li><a href=$vidURL target=\"_blank\">$vidCh - $vidTitle</a></li>"
					fi
				done
				VideoURL="$VideoURL</ul><br>"
			fi
		else
			unset vidlist VideoURL
		fi

		# Extra Scripts
		if ExtraScript=$( echo "$appjson" | jq -e '.extraScript' ) ; then
			appjson=$( echo "$appjson" | jq 'del(.extraScript)' )
			appjson_v3=$( echo "$appjson_v3" | jq 'del(.extraScript)' )
			# If only one entry
			if [ "$(echo "$ExtraScript" | wc -l )" == "1" ]; then
				ExtraHTML="<br><b>Extra useful script: </b><a href=\"${repo}tools/${ExtraScript:1:-1}\" target=\"_blank\">${ExtraScript:1:-1}</a>"

			# If multiples entries
			else
				n_ext=$(echo "$ExtraScript" | jq '. | length')
				ExtraHTML="<br><b>Extra useful scripts:</b><br><ul>"
				for n in $(seq 0 $(( n_ext - 1 ))); do
					ext=$(echo "$ExtraScript" | jq ".[$n]" | tr -d '"')
					ExtraHTML="$ExtraHTML<li><a href=\"${repo}tools/${ext}\" target=\"_blank\">$ext</a></li>"
				done
				ExtraHTML="$ExtraHTML</ul>"
			fi
		else
			unset ExtraHTML ExtraScript
		fi

		# Full Compiled Note
		note="$header$oweb$odoc$PHDoc<br>$Script$ExtraHTML<br>$VideoURL<br>$note"

		appjson=$( echo "$appjson" | jq --arg n "$note" '.note = $n' )
		appjson_v3=$( echo "$appjson_v3" | jq --arg n "$note" '.note = $n' )

		# Splitting into 32 and 64 bit jsons
		appjson_arm32v2=$appjson
		appjson_arm64v2=$appjson
		appjson_amd64v2=$appjson
		appjson_arm32v3=$appjson_v3
		appjson_arm64v3=$appjson_v3
		appjson_amd64v3=$appjson_v3

		# Check if app is to be applied to all (no arch identified)
		# If there is no indication of architecture (32 or 64) on image or stackfile keys
		#   it's to assume that app is to be applied to both templates
		#   else apply specific image/stackfile to indicated architecture
		if  ! echo "$appjson" | grep -qE '"(image|stackfile)":' ; then

			# Parsing arm 32 bit apps (check if there is an image32 or stackfile32)
			if  echo "$appjson_arm32v2" | grep -qE '"(image|stackfile)_arm32":' ; then
				# Rename key
				appjson_arm32v2=$( echo "$appjson_arm32v2" | sed -E 's/"(image|stackfile)_arm32":/"\1":/' )
			else
				# App does not contain 32bit template
				unset appjson_arm32v2
			fi

			# Parsing arm 32 bit apps (check if there is an image32 or stackfile32)
			if  echo "$appjson_arm32v3" | grep -qE '"(image|stackfile)_arm32":' ; then
				# Rename key
				appjson_arm32v3=$( echo "$appjson_arm32v3" | sed -E 's/"(image|stackfile)_arm32":/"\1":/' )
			else
				# App does not contain 32bit template
				unset appjson_arm32v3
			fi

			# Parsing arm 64 bit apps
			if  echo "$appjson_arm64v2" | grep -qE '"(image|stackfile)_arm64":' ; then
				# Rename key
				appjson_arm64v2=$( echo "$appjson_arm64v2" | sed -E 's/"(image|stackfile)_arm64":/"\1":/' )
			else
				# App does not contain 64bit template
				unset appjson_arm64v2
			fi

			# Parsing arm 64 bit apps
			if  echo "$appjson_arm64v3" | grep -qE '"(image|stackfile)_arm64":' ; then
				# Rename key
				appjson_arm64v3=$( echo "$appjson_arm64v3" | sed -E 's/"(image|stackfile)_arm64":/"\1":/' )
			else
				# App does not contain 64bit template
				unset appjson_arm64v3
			fi

			# Parsing amd 64 bit apps
			if  echo "$appjson_amd64v2" | grep -qE '"(image|stackfile)_amd64":' ; then
				# Rename key
				appjson_amd64v2=$( echo "$appjson_amd64v2" | sed -E 's/"(image|stackfile)_amd64":/"\1":/' )
			else
				# App does not contain 64bit template
				unset appjson_amd64v2
			fi

			# Parsing amd 64 bit apps
			if  echo "$appjson_amd64v3" | grep -qE '"(image|stackfile)_amd64":' ; then
				# Rename key
				appjson_amd64v3=$( echo "$appjson_amd64v3" | sed -E 's/"(image|stackfile)_amd64":/"\1":/' )
			else
				# App does not contain 64bit template
				unset appjson_amd64v3
			fi
 		else
		    echo "Skipping empty or non-existent file: $app"
		fi

		# Appending to json_arm32v2
		if [[ -n "$appjson_arm32v2" ]]; then
			# Cleaning App json before adding to template
			appjson_arm32v2=$( echo "$appjson_arm32v2" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_arm32v2=$( echo "$json_arm32v2" | jq --argjson newApp "$appjson_arm32v2" '.templates += [$newApp]' )
		fi

		# Appending to json_arm32v3
		if [[ -n "$appjson_arm32v3" ]]; then
			# Cleaning App json before adding to template
			appjson_arm32v3=$( echo "$appjson_arm32v3" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_arm32v3=$( echo "$json_arm32v3" | jq --argjson newApp "$appjson_arm32v3" '.templates += [$newApp]' )
		fi

		# Appending to json_arm64v2
		if [[ -n "$appjson_arm64v2" ]]; then
			# Cleaning App json before adding to template
			appjson_arm64v2=$( echo "$appjson_arm64v2" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_arm64v2=$( echo "$json_arm64v2" | jq --argjson newApp "$appjson_arm64v2" '.templates += [$newApp]' )
		fi

		# Appending to json_arm64v3
		if [[ -n "$appjson_arm64v3" ]]; then
			# Cleaning App json before adding to template
			appjson_arm64v3=$( echo "$appjson_arm64v3" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_arm64v3=$( echo "$json_arm64v3" | jq --argjson newApp "$appjson_arm64v3" '.templates += [$newApp]' )
		fi

		# Appending to json_amd64v2
		if [[ -n "$appjson_amd64v2" ]]; then
			# Cleaning App json before adding to template
			appjson_amd64v2=$( echo "$appjson_amd64v2" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_amd64v2=$( echo "$json_amd64v2" | jq --argjson newApp "$appjson_amd64v2" '.templates += [$newApp]' )
		fi

		# Appending to json_amd64v3
		if [[ -n "$appjson_amd64v3" ]]; then
			# Cleaning App json before adding to template
			appjson_amd64v3=$( echo "$appjson_amd64v3" | jq 'del(.image_arm32, .image_arm64, .image_amd64, .repository.stackfile_arm32, .repository.stackfile_arm64, .repository.stackfile_amd64)')
			json_amd64v3=$( echo "$json_amd64v3" | jq --argjson newApp "$appjson_amd64v3" '.templates += [$newApp]' )
		fi

		# clean variables before next loop
		unset appjson_arm32v2 appjson_arm64v2 appjson_amd64v2 note
		unset appjson_arm32v3 appjson_arm64v3 appjson_amd64v3
	fi
done

# Create Templates
echo "$json_arm32v2" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_arm32v2"
echo "Creating template $template_arm32v2"
echo "$json_arm64v2" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_arm64v2"
echo "Creating template $template_arm64v2"
echo "$json_amd64v2" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_amd64v2"
echo "Creating template $template_amd64v2"
echo "$json_arm32v3" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_arm32v3"
echo "Creating template $template_arm32v3"
echo "$json_arm64v3" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_arm64v3"
echo "Creating template $template_arm64v3"
echo "$json_amd64v3" | jq --tab '.templates |= sort_by(.title | ascii_upcase)' > "$template_amd64v3"
echo "Creating template $template_amd64v3"

# Keep old template up to date
cp -f "$template_arm32v2" "$Oldtemplate_arm32v2"
echo "Creating template $Oldtemplate_arm32v2"
