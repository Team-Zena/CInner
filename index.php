<?php

	// include config file
	require_once(__DIR__ . '/config.inc.php');

        // Check cmd line args
        if (isset($argv[1])) {
                $COMMIT = $argv[1];
                // construct post array
                $payload = array();
                $payload['after'] = $COMMIT;
                $_POST['payload'] = json_encode($payload);
        }

	// Make sure that the post data contains payload key
	if (!array_key_exists('payload', $_POST)) {
		echo "Request did not contain the 'payload' key \n";
		exit(1);
	}

	// If we are here then we got the pyaload key and it must have a JSON string
	$strPayloadArray = json_decode($_POST['payload'], true);

	if ($strPayloadArray === null) {
		// decoding failed
		echo "Invalid payload \n";
		exit(2);
	}

	// There has to be an 'after' key in the payload contianing the commit hash
	if (!array_key_exists('after', $strPayloadArray)) {
		echo "There was no 'after' key in the Payload! \n";
		exit(3);
	}
	$strCommitHash = $strPayloadArray['after'];

	// The commit has will be 40 characters alphanumeric string
	if (!ctype_alnum($strCommitHash) || strlen($strCommitHash) != 40) {
		echo "Commit hash was not alphanumeric or was not of 40 characters. \n";
		exit(4);
	}

	$curl = curl_init();

//	echo json_encode($strPostInfoArray);

	$startTime = time();

	// Set some options - we are passing in a useragent too here
	curl_setopt_array($curl, array(
		CURLOPT_RETURNTRANSFER => 1,
		CURLOPT_URL            => GITHUB_API_REMOTE . '/statuses/' . $strCommitHash,
		CURLOPT_POST           => 1,
		CURLOPT_POSTFIELDS     => json_encode([
			"state"       => "pending",
			"target_url"  => CINNER_REMOTE_URL . "/pending.php?hash=$strCommitHash&time=$startTime",
			"description" => "Build submitted",
			"context"     => "ci/Tests"
		]),
		CURLOPT_HTTPHEADER     => array(
			"Authorization: token " . GITHUB_TOKEN,
			"User-Agent: " . GITHUB_USER_AGENT
		)
	));

	// Send the request & save response to $resp
	$resp = curl_exec($curl);

	echo "$resp \n";

	// Close request to clear up some resources
	curl_close($curl);

	// write to log file
	$strRepo = REPO_NAME;
	$strLogFile = BUILD_LOG;
	$intTime = time();
	$strStatus = 'submitted';
	$strCommand = 'echo "' . $strCommitHash . '\t' . $strStatus . '\t' . $intTime . '" >> ' . $strLogFile;
	$strOutput = shell_exec($strCommand);

	// post commit vars
	define('PARENT_OUTPUT_NAME', "script_output_${strCommitHash}_" . REPO_NAME . '.txt');
	define('PARENT_OUTPUT', SCRIPT_OUTPUT_DIR . '/' . PARENT_OUTPUT_NAME);


	// execute the script
	$strCommand = '/bin/bash ' . CINNER_LOC . '/script.sh -vsf -c ' . $strCommitHash . ' >> ' . PARENT_OUTPUT . ' 2>&1' . ' &';

	echo "about to run " . $strCommand . "\n";
	$strOutput = shell_exec($strCommand);
	echo $strOutput;

//	echo "Script was run. \n" ;
