<?php

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap
{

    protected function _initDatabase() {

        $dbConfig = $this->getOption('database');
        $db = new Geops_Database_Postgres_Adapter($dbConfig['params']);

        // enable profiling when run in a webserver in development
        if ((APPLICATION_ENV == 'development') && (php_sapi_name() != 'cli')) {
            $db->setProfileQuerytime(true);
            $db->setProfileHttpHeaders(true);
        }

        // explicitly set the client encoding for the database connection
        $db->query("set client_encoding to 'utf-8'; /*Bootstrap::_initDatabase*/");

        Zend_Db_Table_Abstract::setDefaultAdapter($db);

        $registry = Zend_Registry::getInstance();
        $registry->set('db', $db);
    }

    protected function _initPagination() {

        Zend_View_Helper_PaginationControl::setDefaultViewPartial('partial/pagination-control.phtml');
    }

    protected function _initLayout()
    {
        Zend_Layout::startMvc();
    }

    /**
     * convert PHP Errors to exceptions.
     *
     * this might be configured in the config file by settings
     * the error_handler key.
     *
     * Default is converting  all errors matching E_ALL
     * to exceptions
     */
    protected function _initErrorHandling()
    {
        $error_types = E_ALL;
        $error_types_config = $this->getOption('error_handler');
        if (!empty($error_types_config)) { // eval will not work with an empty string
            // use eval to make a PHP int of the strings containing the constants
            $error_types = eval("return ($error_types_config);");
        }

        set_error_handler(
            create_function('$a, $b, $c, $d', 'throw new ErrorException($b, 0, $a, $c, $d);'),
            $error_types
        );
    }

}

