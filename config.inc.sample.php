<?php

/* Config file for cinner index.php */

// Github webhook configuration
define('GITHUB_API_REMOTE', 'https://api.github.com/repos/username/repo');
define('GITHUB_TOKEN', '12345678');
define('GITHUB_USER_AGENT', 'username');

// # URL for accessing cinner from Github
define('CINNER_REMOTE_URL', 'https://ci.example.com');

// Git repository which we fetch and run test cases for
define('REPO_NAME', 'repo.example.com');
define('REPO_LOC', '/www/' . REPO_NAME);

// Location where cinner is present and stores it logs
define('CINNER_LOC', '/www/cinner');
define('SCRIPT_OUTPUT_DIR', CINNER_LOC . '/log');
define('BUILD_LOG_NAME', 'cinner_build_log_' . REPO_NAME . '.txt');
define('BUILD_LOG', SCRIPT_OUTPUT_DIR . '/' . BUILD_LOG_NAME);
