<?php

class BohrprofilModel extends Zend_Db_Table_Abstract {

    protected $_name = 'bohrung.bohrprofil';

    protected $_bohrprofilSQL = 'select b.*, ST_AsText(b.wkb_geometry) as wkt_geometry,
                    ST_X(b.wkb_geometry) as x_koordinate, ST_Y(b.wkb_geometry) as y_koordinate,
                    c1.kurztext as tektonik_text, c2.kurztext as fmfelso_text,
                    c3.kurztext as fmeto_text, c4.kurztext as quali_text
                from bohrung.bohrprofil b
                left join bohrung.code c1 on b.tektonik = c1.code_id
                left join bohrung.code c2 on b.fmfelso = c2.code_id
                left join bohrung.code c3 on b.fmeto = c3.code_id
                left join bohrung.code c4 on b.quali = c4.code_id ';

    protected $_schichtenSQL = 'select s.*, cs.text as schicht_text, c1.kurztext as quali_text
                from bohrung.schicht s
                left join bohrung.codeschicht cs on s.schichten_id = cs.codeschicht_id
                left join bohrung.code c1 on s.quali = c1.code_id
                where bohrprofil_id = ? order by tiefe asc ';

    protected $_vorkommnisseSQL = 'select v.*, c1.kurztext as typ_text,
                    c2.kurztext as subtyp_text, c3.kurztext as quali_text
                from bohrung.vorkommnis v
                left join bohrung.code c1 on v.typ = c1.code_id
                left join bohrung.code c2 on v.subtyp = c2.code_id
                left join bohrung.code c3 on v.quali = c3.code_id
                where bohrprofil_id = ? order by tiefe asc ';

    public function getBohrprofile($bohrung_id) {

        $bohrprofile = $this->_db->fetchAll(
            $this->_bohrprofilSQL . 'where b.bohrung_id = ? order by archive, archive_date desc, mut_date',
            array($bohrung_id)
        );

        foreach ($bohrprofile as &$bohrprofil) {
            $bohrprofil['schichten'] = $this->_db->fetchAll(
                $this->_schichtenSQL,
                array($bohrprofil['bohrprofil_id'])
            );
            $bohrprofil['vorkommnisse'] = $this->_db->fetchAll(
                $this->_vorkommnisseSQL,
                array($bohrprofil['bohrprofil_id'])
            );
        }

        return $bohrprofile;
    }

    public function getBohrprofil($bohrprofil_id) {

        $bohrprofil = $this->_db->fetchRow(
            $this->_bohrprofilSQL . 'where b.bohrprofil_id = ? ',
            array($bohrprofil_id)
        );

        $bohrprofil['schichten'] = $this->_db->fetchAll(
            $this->_schichtenSQL,
            array($bohrprofil_id)
        );

        $bohrprofil['vorkommnisse'] = $this->_db->fetchAll(
            $this->_vorkommnisseSQL,
            array($bohrprofil_id)
        );

        return $bohrprofil;
    }

    public function getStandortId($bohrprofil_id) {

        return $this->_db->fetchOne(
            'select standort_id from bohrung.bohrprofil
            join bohrung.bohrung using (bohrung_id)
            where bohrprofil_id = ? ',
            array($bohrprofil_id)
        );
    }

    public function cloneBohrprofil($bohrprofil_id) {
        return $this->_db->fetchOne('select bohrung.bohrprofil_clone( ? )', array($bohrprofil_id));
    }

    public function insertBohrprofil($data) {

        $this->_db->beginTransaction();

        if (!$data['archive']) {
            $archive = array('archive' => '1');
            $where = array('bohrung_id = ?' => $data['bohrung_id']);
            $this->_db->update('bohrung.bohrprofil', $archive, $where);
        }

        $bohrprofilData = $this->prepareData($data);
        $bohrprofil_id = $this->insert($bohrprofilData);

        $this->_db->commit();

        if (is_array($data['schichten'])) {
            $schichtModel = new SchichtModel();
            $schichtModel->saveSchichten($data['schichten'], $bohrprofil_id);
        }

        if (is_array($data['vorkommnisse'])) {
            $vorkommnisModel = new VorkommnisModel();
            $vorkommnisModel->saveVorkommnisse($data['vorkommnisse'], $bohrprofil_id);
        }
    }

    public function updateBohrprofil($bohrprofil_id, $data) {

        if (is_array($data['schichten'])) {
            $schichtModel = new SchichtModel();
            $schichtModel->saveSchichten($data['schichten'], $bohrprofil_id);
        }

        if (is_array($data['vorkommnisse'])) {
            $vorkommnisModel = new VorkommnisModel();
            $vorkommnisModel->saveVorkommnisse($data['vorkommnisse'], $bohrprofil_id);
        }

        $this->_db->beginTransaction();

        if (!$data['archive']) {
            $archive = array('archive' => '1');
            $where = array('bohrung_id = ?' => $data['bohrung_id']);
            $this->_db->update('bohrung.bohrprofil', $archive, $where);
        }

        $data = $this->prepareData($data);
        $where = array('bohrprofil_id = ?' => $bohrprofil_id);
        $this->_db->update('bohrung.bohrprofil', $data, $where);

        $this->_db->commit();
    }

    private function prepareData($data) {

        $data['kote']     = empty($data['kote'])     ? NULL : (int)$data['kote'];
        $data['endteufe'] = empty($data['endteufe']) ? NULL : (int)$data['endteufe'];
        $data['tektonik'] = empty($data['tektonik']) ? NULL : (int)$data['tektonik'];
        $data['fmfelso']  = empty($data['fmfelso'])  ? NULL : (int)$data['fmfelso'];
        $data['fmeto']    = empty($data['fmeto'])    ? NULL : (int)$data['fmeto'];
        $data['quali']    = empty($data['quali'])    ? NULL : (int)$data['quali'];
        $data['datum']    = empty($data['datum'])    ? NULL : $data['datum'];
        $data['archive']  = ($data['archive'] == 1)  ? 1 : 0;
        $data['bohrung_id'] = (int)$data['bohrung_id'];

        $geometryModel = new GeometryModel();
        $data['wkb_geometry'] = $geometryModel->getPoint($data['x_koordinate'],$data['y_koordinate']);
        unset($data['x_koordinate']);
        unset($data['y_koordinate']);
        unset($data['schichten']);
        unset($data['vorkommnisse']);

        return $data;
    }
}
