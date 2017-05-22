<?php

class GeometryModel extends Zend_Db_Table_Abstract {

    public function asText($geometry) {
        return $this->_db->fetchOne('select ST_AsText(?)', array($geometry));
    }

    public function getPoint($x_koordinate, $y_koordinate, $srid = 2056) {
        return $this->_db->fetchOne('select ST_SetSRID(ST_Point(?, ?), ?)', array($x_koordinate, $y_koordinate, $srid));
    }

}
