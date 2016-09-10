<?php

namespace repository;


trait MailAddressRepository {
    function saveMailAddress($mailAddress) {
        echo __FUNCTION__ . "\n";
    }

    function findMailAddress($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}