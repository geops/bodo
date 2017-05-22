<?php

class BohrungModel extends Zend_Db_Table_Abstract {

    protected $_name = 'bohrung.bohrung';

    public function getBohrungen($standort_id) {

        $bohrungen = $this->_db->fetchAll(
            'select b.*, c1.kurztext as bohrart_text, c2.kurztext as bohrzweck_text,
                    c3.kurztext as ablenkung_text, c4.kurztext as quali_text,
                    coalesce(b.mut_date, b.new_date) as sort
                from bohrung.bohrung b
                left join bohrung.code c1 on b.bohrart = c1.code_id
                left join bohrung.code c2 on b.bohrzweck = c2.code_id
                left join bohrung.code c3 on b.ablenkung = c3.code_id
                left join bohrung.code c4 on b.quali = c4.code_id
                where standort_id = ? order by sort desc limit 15',
            array($standort_id)
        );

        $bohrprofilModel = new BohrprofilModel();

        foreach ($bohrungen as &$bohrung) {
            $bohrung['bohrprofile'] = $bohrprofilModel->getBohrprofile($bohrung['bohrung_id']);
        }

        return $bohrungen;
    }

    public function getStandortId($bohrung_id) {

        return $this->_db->fetchOne(
            'select standort_id from bohrung.bohrung where bohrung_id = ? ',
            array($bohrung_id)
        );
    }

    public function insertBohrung($data) {

        $data = $this->prepareData($data);
        return $this->_db->insert('bohrung.bohrung', $data);
    }

    public function updateBohrung($bohrung_id, $data) {

        $data = $this->prepareData($data);
        $where = array('bohrung_id = ?' => $bohrung_id);
        return $this->_db->update('bohrung.bohrung', $data, $where);
    }

    private function prepareData($data) {
        $data['bohrart']   = empty($data['bohrart'])   ? NULL : (int)$data['bohrart'];
        $data['bohrzweck'] = empty($data['bohrzweck']) ? NULL : (int)$data['bohrzweck'];
        $data['ablenkung'] = empty($data['ablenkung']) ? NULL : (int)$data['ablenkung'];
        $data['quali']     = empty($data['quali'])     ? NULL : (int)$data['quali'];
        $data['datum']     = empty($data['datum'])     ? NULL : $data['datum'];
        $data['durchmesserbohrloch'] = empty($data['durchmesserbohrloch']) ? NULL : (int)$data['durchmesserbohrloch'];
        $data['standort_id'] = (int)$data['standort_id'];
        return $data;
    }
}
