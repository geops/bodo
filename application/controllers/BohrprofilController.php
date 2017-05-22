<?php

class BohrprofilController extends Zend_Controller_Action {

    public function init() {

        $this->view->messages = $this->_helper->FlashMessenger->getMessages();
    }

    public function editAction() {

        $bohrprofil_id = (int)$this->_request->getParam('bohrprofil_id');

        if (empty($this->view->messages)) {
            $bohrprofilModel = new BohrprofilModel();
            $this->view->bohrprofil = $bohrprofilModel->getBohrprofil($bohrprofil_id);
        } else {
            $formSession = new Zend_Session_Namespace('bodo.form');
            $this->view->bohrprofil = $formSession->data;
            $this->view->bohrprofil['bohrprofil_id'] = $bohrprofil_id;
        }

        $this->addCodesToView();
    }


    public function cloneAction() {

        $bohrprofil_id = (int)$this->_request->getParam('bohrprofil_id');

        $bohrprofilModel = new BohrprofilModel();
        $bohrprofil_id = $bohrprofilModel->cloneBohrprofil($bohrprofil_id);

        $this->_redirect(ROOT_DIR . 'bohrprofil/edit?bohrprofil_id=' . $bohrprofil_id);
    }

    public function newAction() {

        $bohrung_id = (int)$this->_request->getParam('bohrung_id');

        $this->addCodesToView();
        $this->view->bohrung_id = $bohrung_id;

        if (!empty($this->view->messages)) {
            $formSession = new Zend_Session_Namespace('bodo.form');
            $this->view->bohrprofil = $formSession->data;
        }
    }

    public function insertAction() {

        $bohrprofilModel = new BohrprofilModel();
        $data = $this->getData();

        try {

            $bohrprofil_id = $bohrprofilModel->insertBohrprofil($data);

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));

            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_redirect(ROOT_DIR . 'bohrprofil/new?bohrung_id=' . $data['bohrung_id']);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrprofil erstellt.',
        ));

        $bohrungModel = new BohrungModel();
        $standort_id = $bohrungModel->getStandortId($data['bohrung_id']);

        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
    }

    public function updateAction() {

        $bohrprofil_id = (int)$this->_request->getParam('bohrprofil_id');
        $data = $this->getData();
        $bohrprofilModel = new BohrprofilModel();

        try {

            $bohrprofilModel->updateBohrprofil($bohrprofil_id, $data);

        } catch (Exception $exc) {
            // PDOException and Geops_Database_Exception possible.

            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'bohrprofil/edit?bohrprofil_id=' . $bohrprofil_id);
        }

        $standort_id = $bohrprofilModel->getStandortId($bohrprofil_id);

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrprofil aktualisiert.',
        ));
        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
    }

    public function removeAction() {
        $bohrprofil_id = (int)$this->_request->getParam('bohrprofil_id');
        $this->view->bohrprofil_id = $bohrprofil_id;
    }

    public function deleteAction() {

        $bohrprofil_id = (int)$this->_request->getParam('bohrprofil_id');

        $bohrprofilModel = new BohrprofilModel();
        $standort_id = $bohrprofilModel->getStandortId($bohrprofil_id);

        if (!$standort_id) {
            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => 'Bohrprofil nicht gefunden.',
            ));
            $this->_redirect(ROOT_DIR . 'standort/list');
        }

        try {

            $bohrprofilModel->delete(array('bohrprofil_id = ?' => $bohrprofil_id));

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrprofil gelöscht.',
        ));
        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
    }

    private function addCodesToView() {
        $codeModel = new CodeModel();
        $this->view->qualiOptions        = $codeModel->getCodes('bohrprofil', 'quali');
        $this->view->tektonikOptions     = $codeModel->getCodes('bohrprofil', 'tektonik');
        $this->view->fmfelsoOptions      = $codeModel->getCodes('bohrprofil', 'fmfelso');
        $this->view->fmetoOptions        = $codeModel->getCodes('bohrprofil', 'fmeto');
        $this->view->schichtQualiOptions = $codeModel->getCodes('schicht', 'quali');
        $this->view->schichtOptions      = $codeModel->getSchichten();
        $this->view->vorkommnisTypOptions = $codeModel->getCodes('vorkommnis', 'typ');
        $this->view->vorkommnisSubtypOptions = $codeModel->getCodes('vorkommnis', 'subtyp');
        $this->view->vorkommnisQualiOptions = $codeModel->getCodes('vorkommnis', 'quali');
    }

    private function getData() {

        return array(
            'bohrung_id'   => $this->_request->getParam('bohrung_id'),
            'datum'        => $this->_request->getParam('datum'),
            'bemerkung'    => $this->_request->getParam('bemerkung'),
            'kote'         => $this->_request->getParam('kote'),
            'endteufe'     => $this->_request->getParam('endteufe'),
            'tektonik'     => $this->_request->getParam('tektonik'),
            'fmfelso'      => $this->_request->getParam('fmfelso'),
            'fmeto'        => $this->_request->getParam('fmeto'),
            'quali'        => $this->_request->getParam('quali'),
            'qualibem'     => $this->_request->getParam('qualibem'),
            'archive'      => $this->_request->getParam('archive'),
            'x_koordinate' => $this->_request->getParam('x_koordinate'),
            'y_koordinate' => $this->_request->getParam('y_koordinate'),
            'schichten'    => $this->_request->getParam('schichten'),
            'vorkommnisse' => $this->_request->getParam('vorkommnisse'),
        );
    }
}
