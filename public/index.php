<?php
// Define path to application directory
defined('APPLICATION_PATH')
    || define('APPLICATION_PATH', realpath(dirname(__FILE__) . '/../application'));

// Define application environment
function get_environment() {
    $env = 'development';
    $envfile = realpath(dirname(__FILE__). "/../") . "/ENVIRONMENT";
    if (is_file($envfile)) {
        $new_env = trim(file_get_contents($envfile));
        if (!empty($new_env)) {
            $env = $new_env;
        }
        else {
            die("Please specify an environment in $envfile");
        }
    }
    else {
        die("Please create the ENVIRONMENT file in $envfile");
    };
    header("X-BODO-Environment: $env");
    return $env;
}
define('APPLICATION_ENV', get_environment());

function get_release() {
    $release = "unknown";
    $relfile = realpath(dirname(__FILE__). "/../") . "/RELEASE";
    if (is_file($relfile)) {
        $release = trim(file_get_contents($relfile));
    }
    header("X-BODO-Release: $release");
    return $release;
}
define('APPLICATION_RELEASE', get_release());

/**
 * assemble the root_dir path
 *
 * this function also removes the port numbers
 * when the server is running on the standard port.
 * this reduces possible redirects --> JS requests are
 * les likely to fail.
 */
function get_rootdir() {
    $protocol = isset($_SERVER['HTTPS']) ? 'https' : 'http';

    // only include the portnumber if on a non-standard port
    // to avoid failing redirects in JS requests
    $port = "";
    if ((($protocol == 'http') && ($_SERVER['SERVER_PORT']!='80')) ||
        (($protocol == 'https') && ($_SERVER['SERVER_PORT']!='443'))) {
        $port = $_SERVER['SERVER_PORT'];
    }

    $script_name = str_replace('//', '/', dirname($_SERVER['SCRIPT_NAME']));

    return implode(
        array(
            $protocol,
            "://",
            $_SERVER['SERVER_NAME'],
            empty($port) ? "" : ":".$port,
            $script_name,
            "/"
        )
    );
}
define('ROOT_DIR', get_rootdir());

// Ensure library/ is on include_path
set_include_path(implode(PATH_SEPARATOR, array(
    realpath(APPLICATION_PATH . '/../library'),
    APPLICATION_PATH . '/models',
    get_include_path(),
)));

require_once 'Zend/Loader/Autoloader.php';
$autoloader = Zend_Loader_Autoloader::getInstance();
$autoloader->setFallbackAutoloader(true);

/** Zend_Application */
require_once 'Zend/Application.php';

// Create application, bootstrap, and run
$application = new Zend_Application(
    APPLICATION_ENV,
    APPLICATION_PATH . '/configs/application.ini'
);
$application->bootstrap()
            ->run();