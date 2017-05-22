<?php

class StandortModel extends Zend_Db_Table_Abstract {

    protected $_name = 'bohrung.standort';

    public function listStandorte($standort_id = null, $bezeichnung = null) {

        $where = '';
        $fields = array();
        $params = array();
        if (!empty($standort_id)) {
            $fields['s.standort_id = ?'] = $standort_id;
        }
        if (!empty($bezeichnung)) {
            $fields["s.bezeichnung ilike ? ESCAPE '='"] = '%'.preg_replace('[%_=]', '=$0', $bezeichnung).'%';
        }

        if (!empty($fields)) {
            $where = 'where ' . implode(' and ', array_keys($fields));
            $params = array_values($fields);
        }

        return $this->_db->fetchAll(
            'select s.*, ST_AsText(s.wkb_geometry) as wkt_geometry, c1.kurztext as quali_text,
                coalesce(s.mut_date, s.new_date) as sort
                from bohrung.standort s
                left join bohrung.code c1 on s.quali = c1.code_id ' .
                $where . ' order by sort desc limit 100',
            $params
        );
    }

    public function getStandort($standort_id) {

        $row = $this->_db->fetchRow(
            'select s.*, ST_AsText(s.wkb_geometry) as wkt_geometry,
                    ST_X(s.wkb_geometry) as x_koordinate, ST_Y(s.wkb_geometry) as y_koordinate,
                    c1.kurztext as quali_text
                from bohrung.standort s
                left join bohrung.code c1 on s.quali = c1.code_id
                where standort_id = ?',
            array($standort_id)
        );

        if ($row) {
            // Strip whitespace from character(40) field.
            $row['gbnummer'] = trim($row['gbnummer']);
        }

        return $row;
    }

    public function updateStandort($standort_id, $data) {

        $data = $this->prepareData($data);
        $where = array('standort_id = ?' => $standort_id);
        return $this->_db->update('bohrung.standort', $data, $where);
    }

    public function prepareData($data) {

        $data['anzbohrloch'] = empty($data['anzbohrloch']) ? NULL : (int)$data['anzbohrloch'];
        $data['gembfs']      = empty($data['gembfs'])      ? NULL : (int)$data['gembfs'];
        $data['gaso_nr']     = empty($data['gaso_nr'])     ? NULL : (int)$data['gaso_nr'];
        $data['quali']       = empty($data['quali'])       ? NULL : (int)$data['quali'];

        $geometryModel = new GeometryModel();
        $data['wkb_geometry'] = $geometryModel->getPoint($data['x_koordinate'], $data['y_koordinate']);
        unset($data['x_koordinate']);
        unset($data['y_koordinate']);

        return $data;
    }
}
